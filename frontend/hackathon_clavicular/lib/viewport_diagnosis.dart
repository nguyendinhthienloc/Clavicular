import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math' as math;
import 'config/app_config.dart';

class ViewportDiagnosis extends StatefulWidget {
  const ViewportDiagnosis({
    super.key,
    required this.isDarkMode,
    this.selectedBodyParts,
    this.selectedPart,
    required this.selectedViewport,
    required this.onViewportChanged,
    this.onDiagnosisReady,
  });

  final bool isDarkMode;
  final List<String>? selectedBodyParts;
  final String? selectedPart;
  final String selectedViewport;
  final ValueChanged<String> onViewportChanged;
  final ValueChanged<String>? onDiagnosisReady;

  @override
  State<ViewportDiagnosis> createState() => _ViewportDiagnosisState();
}

class _ViewportDiagnosisState extends State<ViewportDiagnosis>
    with TickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();
  late final Dio _dio;
  AnimationController? _gradientController;
  AnimationController? _micPulseController;
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  String? _selectedSeverity;
  String? _selectedPainType;
  String? _selectedDuration;
  String? _selectedActivity;
  bool _useCurrentLocation = true;
  bool _isSubmitting = false;
  bool _isLocating = false;
  bool _isListeningNotes = false;
  double? _lat;
  double? _lng;
  String? _locationStatus;

  List<String> get _resolvedSelectedBodyParts {
    final List<String> selectedBodyParts =
        widget.selectedBodyParts ?? const <String>[];
    final List<String> sanitizedParts = selectedBodyParts
        .map((String value) => value.trim())
        .where(
          (String value) => value.isNotEmpty && value != 'Nothing selected',
        )
        .toList();

    if (sanitizedParts.isNotEmpty) {
      return sanitizedParts;
    }

    final String part = (widget.selectedPart ?? '').trim();
    if (part.isEmpty || part == 'Nothing selected') {
      return const <String>[];
    }

    return <String>[part];
  }

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  Future<void> _toggleNotesSpeechToText() async {
    if (_isListeningNotes) {
      await _stopNotesSpeechToText();
      return;
    }

    try {
      final bool isAvailable = await _speechToText.initialize(
        onStatus: (String status) {
          if (status == 'done' || status == 'notListening') {
            if (!mounted) {
              return;
            }
            _micPulseController?.stop();
            _micPulseController?.value = 0;
            setState(() {
              _isListeningNotes = false;
            });
          }
        },
        onError: (error) {
          if (!mounted) {
            return;
          }
          _micPulseController?.stop();
          _micPulseController?.value = 0;
          setState(() {
            _isListeningNotes = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('STT error: ${error.errorMsg}')),
          );
        },
      );

      if (!isAvailable) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available.')),
        );
        return;
      }

      setState(() {
        _isListeningNotes = true;
      });
      _micPulseController?.repeat(reverse: true);

      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) {
            return;
          }
          setState(() {
            _notesController.text = result.recognizedWords;
            _notesController.selection = TextSelection.fromPosition(
              TextPosition(offset: _notesController.text.length),
            );
          });
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _micPulseController?.stop();
      _micPulseController?.value = 0;
      setState(() {
        _isListeningNotes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start voice notes: $error')),
      );
    }
  }

  Future<void> _stopNotesSpeechToText() async {
    try {
      await _speechToText.stop();
    } finally {
      _micPulseController?.stop();
      _micPulseController?.value = 0;
      if (mounted) {
        setState(() {
          _isListeningNotes = false;
        });
      }
    }
  }

  Future<bool> _resolveCurrentLocation({bool showLoading = true}) async {
    if (_isLocating) {
      return _lat != null && _lng != null;
    }

    if (showLoading && mounted) {
      setState(() {
        _isLocating = true;
        _locationStatus = 'Detecting location...';
      });
    } else {
      _isLocating = true;
    }

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationStatus = 'Location service is disabled.';
          });
        }
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationStatus = 'Location permission denied.';
          });
        }
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationStatus =
                'Location permission denied permanently. Enable it in app settings.';
          });
        }
        return false;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
          _locationStatus = 'Location ready.';
        });
      } else {
        _lat = position.latitude;
        _lng = position.longitude;
      }
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationStatus =
              'Could not get location. You can still submit without it.';
        });
      }
      return false;
    } finally {
      _isLocating = false;
      if (showLoading && mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _submitDiagnosis() async {
    final List<String> bodyParts = _resolvedSelectedBodyParts;
    if (_isSubmitting || bodyParts.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_useCurrentLocation) {
        await _resolveCurrentLocation(showLoading: false);
      }

      final Response<dynamic> response = await _dio
          .post<dynamic>(
            '${AppConfig.apiEndpoint}/ai/diagnose',
            data: <String, dynamic>{
              'bodyParts': bodyParts,
              'severity': _selectedSeverity ?? 'Mild',
              'painType': _selectedPainType ?? 'sharp',
              'duration': _selectedDuration ?? '< 1 week',
              'trigger': _selectedActivity ?? 'Rest',
              'lat': _useCurrentLocation ? _lat : null,
              'lng': _useCurrentLocation ? _lng : null,
            },
            options: Options(
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ),
          )
          .timeout(const Duration(seconds: 35));

      String message = 'No diagnosis review returned.';
      final dynamic root = response.data;
      if (root is Map<String, dynamic>) {
        final dynamic payload = root['payload'];
        final String extracted = _extractDiagnosisText(payload);
        if (extracted.isNotEmpty) {
          message = extracted;
        }
      }

      widget.onDiagnosisReady?.call(message);
    } on DioException catch (error) {
      widget.onDiagnosisReady?.call(
        'Failed to get diagnosis review.\n\n${error.message}',
      );
    } catch (error) {
      widget.onDiagnosisReady?.call(
        'Unexpected error while loading diagnosis review.\n\n$error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _extractDiagnosisText(dynamic payload) {
    if (payload is String) {
      return payload.trim();
    }

    if (payload is! Map<String, dynamic>) {
      return '';
    }

    final dynamic textField = payload['text'];
    if (textField is String && textField.trim().isNotEmpty) {
      return textField.trim();
    }

    final dynamic dataField = payload['data'];
    if (dataField is String && dataField.trim().isNotEmpty) {
      return dataField.trim();
    }

    if (dataField is Map<String, dynamic>) {
      final dynamic nestedText = dataField['text'];
      if (nestedText is String && nestedText.trim().isNotEmpty) {
        return nestedText.trim();
      }

      final dynamic nestedData = dataField['data'];
      if (nestedData is Map<String, dynamic>) {
        final dynamic deeplyNestedText = nestedData['text'];
        if (deeplyNestedText is String && deeplyNestedText.trim().isNotEmpty) {
          return deeplyNestedText.trim();
        }
      }
    }

    return '';
  }

  @override
  void dispose() {
    _speechToText.stop();
    _notesController.dispose();
    _micPulseController?.dispose();
    _gradientController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _gradientController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _micPulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final bool isDarkMode = widget.isDarkMode;

    final Color viewportBackground = isDarkMode
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF4F6F8);
    final Color viewportBorder = isDarkMode
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFD4D9E0);
    final Color composerBackground = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFFFFFFF);
    final Color composerBorder = isDarkMode
        ? const Color(0xFF454545)
        : const Color(0xFFD1D5DB);
    final Color inputTextColor = isDarkMode
        ? const Color(0xFFE3E3E3)
        : const Color(0xFF111827);
    final Color inputHintColor = isDarkMode
        ? const Color(0xFF9C9C9C)
        : const Color(0xFF6B7280);
    final Color statusColor = isDarkMode
        ? const Color(0xFFB6C2D1)
        : const Color(0xFF475569);
    final Color listeningMicColor = isDarkMode
      ? const Color(0xFF60A5FA)
      : const Color(0xFF2563EB);
    final String normalizedViewport = widget.selectedViewport
      .trim()
      .toLowerCase();
    final String viewportValue =
      (normalizedViewport == 'chat' || normalizedViewport == 'diagnosis')
      ? normalizedViewport
      : 'diagnosis';
    final List<String> selectedBodyParts = _resolvedSelectedBodyParts;
    final String selectedBodyPartsLabel = selectedBodyParts.isEmpty
        ? 'Select body part in pain'
        : selectedBodyParts.join(', ');
    final List<Color> outlineColors = isDarkMode
        ? const [Color(0xFF60A5FA), Color(0xFF1D4ED8)]
        : const [Color(0xFF93C5FD), Color(0xFF2563EB)];

    return AnimatedBuilder(
      animation: _gradientController!,
      builder: (context, child) {
        final double shift = -1 + (_gradientController!.value * 2);
        final LinearGradient animatedOutlineGradient = LinearGradient(
          begin: Alignment(-1 + shift, 0),
          end: Alignment(1 + shift, 0),
          colors: outlineColors,
        );
        final LinearGradient animatedButtonGradient = LinearGradient(
          begin: Alignment(-1 + shift, 0),
          end: Alignment(1 + shift, 0),
          colors: const [Color(0xFF60A5FA), Color(0xFF2563EB)],
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              gradient: animatedOutlineGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              margin: const EdgeInsets.all(1.4),
              decoration: BoxDecoration(
                color: viewportBackground,
                border: Border.all(color: viewportBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scaffold(
                backgroundColor: viewportBackground,
                body: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool compactHeight = constraints.maxHeight < 740;
                    final bool compactWidth = constraints.maxWidth < 430;
                    final double horizontalPadding = compactWidth ? 12 : 16;
                    final double fieldGap = compactHeight ? 10 : 12;
                    final double notesHeight = compactHeight ? 80 : 92;
                    final double notesOuterRadius = compactHeight ? 20 : 24;
                    final double notesInnerRadius = compactHeight ? 18.6 : 22.6;
                    final double submitHeight = compactHeight ? 50 : 56;
                    final double submitFontSize = compactWidth ? 18 : 22;

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            compactHeight ? 8 : 10,
                            horizontalPadding,
                            8,
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: composerBackground,
                                border: Border.all(color: viewportBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ViewportToggleButton(
                                      label: 'Chat',
                                      selected: viewportValue == 'chat',
                                      isDarkMode: isDarkMode,
                                      gradient: animatedOutlineGradient,
                                      onTap: () => widget.onViewportChanged('chat'),
                                    ),
                                  ),
                                  Expanded(
                                    child: _ViewportToggleButton(
                                      label: 'Diagnosis',
                                      selected: viewportValue == 'diagnosis',
                                      isDarkMode: isDarkMode,
                                      gradient: animatedOutlineGradient,
                                      onTap: () =>
                                          widget.onViewportChanged('diagnosis'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              compactHeight ? 8 : 10,
                              horizontalPadding,
                              compactHeight ? 10 : 12,
                            ),
                            child: Column(
                              children: [
                            DropdownButtonFormField<String>(
                              initialValue: selectedBodyPartsLabel,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: composerBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                              ),
                              style: GoogleFonts.montserrat(
                                color: inputTextColor,
                              ),
                              dropdownColor: composerBackground,
                              items: [
                                DropdownMenuItem(
                                  value: selectedBodyPartsLabel,
                                  child: Text(
                                    selectedBodyPartsLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              selectedItemBuilder: (BuildContext context) {
                                return <Widget>[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      selectedBodyPartsLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        color: inputTextColor,
                                      ),
                                    ),
                                  ),
                                ];
                              },
                              onChanged: (_) {},
                            ),
                            SizedBox(height: fieldGap),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSeverity,
                              decoration: InputDecoration(
                                hintText: 'Select severity',
                                hintStyle: GoogleFonts.montserrat(
                                  color: inputHintColor,
                                ),
                                filled: true,
                                fillColor: composerBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                              ),
                              style: GoogleFonts.montserrat(
                                color: inputTextColor,
                              ),
                              dropdownColor: composerBackground,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Mild',
                                  child: Text('Mild'),
                                ),
                                DropdownMenuItem(
                                  value: 'Moderate',
                                  child: Text('Moderate'),
                                ),
                                DropdownMenuItem(
                                  value: 'Severe',
                                  child: Text('Severe'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedSeverity = value;
                                });
                              },
                            ),
                            SizedBox(height: fieldGap),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedPainType,
                              decoration: InputDecoration(
                                hintText: 'Select pain type',
                                hintStyle: GoogleFonts.montserrat(
                                  color: inputHintColor,
                                ),
                                filled: true,
                                fillColor: composerBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                              ),
                              style: GoogleFonts.montserrat(
                                color: inputTextColor,
                              ),
                              dropdownColor: composerBackground,
                              items: const [
                                DropdownMenuItem(
                                  value: 'sharp',
                                  child: Text('Sharp'),
                                ),
                                DropdownMenuItem(
                                  value: 'dull',
                                  child: Text('Dull'),
                                ),
                                DropdownMenuItem(
                                  value: 'throbbing',
                                  child: Text('Throbbing'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedPainType = value;
                                });
                              },
                            ),
                            SizedBox(height: fieldGap),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDuration,
                              decoration: InputDecoration(
                                hintText: 'Select duration',
                                hintStyle: GoogleFonts.montserrat(
                                  color: inputHintColor,
                                ),
                                filled: true,
                                fillColor: composerBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                              ),
                              style: GoogleFonts.montserrat(
                                color: inputTextColor,
                              ),
                              dropdownColor: composerBackground,
                              items: const [
                                DropdownMenuItem(
                                  value: '< 1 week',
                                  child: Text('< 1 week'),
                                ),
                                DropdownMenuItem(
                                  value: '1-4 weeks',
                                  child: Text('1-4 weeks'),
                                ),
                                DropdownMenuItem(
                                  value: '> 1 month',
                                  child: Text('> 1 month'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedDuration = value;
                                });
                              },
                            ),
                            SizedBox(height: fieldGap),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedActivity,
                              decoration: InputDecoration(
                                hintText: 'Select activity trigger',
                                hintStyle: GoogleFonts.montserrat(
                                  color: inputHintColor,
                                ),
                                filled: true,
                                fillColor: composerBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: composerBorder),
                                ),
                              ),
                              style: GoogleFonts.montserrat(
                                color: inputTextColor,
                              ),
                              dropdownColor: composerBackground,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Rest',
                                  child: Text('Rest'),
                                ),
                                DropdownMenuItem(
                                  value: 'Movement',
                                  child: Text('Movement'),
                                ),
                                DropdownMenuItem(
                                  value: 'Sports',
                                  child: Text('Sports'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedActivity = value;
                                });
                              },
                            ),
                            SizedBox(height: fieldGap),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: composerBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: composerBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Use current location for nearby clinics',
                                          maxLines: compactWidth ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            color: inputTextColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: _useCurrentLocation,
                                        onChanged: (bool value) {
                                          setState(() {
                                            _useCurrentLocation = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      TextButton.icon(
                                        onPressed: _isLocating
                                            ? null
                                            : () => _resolveCurrentLocation(),
                                        icon: _isLocating
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.my_location),
                                        label: Text(
                                          _isLocating
                                              ? 'Locating...'
                                              : 'Show location',
                                          style: GoogleFonts.montserrat(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_locationStatus != null &&
                                      _locationStatus!.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        _locationStatus!,
                                        style: GoogleFonts.montserrat(
                                          color: statusColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: fieldGap + 4),
                            Container(
                              width: double.infinity,
                              height: notesHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  notesOuterRadius,
                                ),
                                gradient: animatedOutlineGradient,
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(1.4),
                                decoration: BoxDecoration(
                                  color: composerBackground,
                                  borderRadius: BorderRadius.circular(
                                    notesInnerRadius,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    10,
                                    14,
                                    10,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _notesController,
                                          maxLines: 1,
                                          textInputAction:
                                              TextInputAction.done,
                                          style: GoogleFonts.montserrat(
                                            color: inputTextColor,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Add notes for diagnosis...',
                                            hintStyle: GoogleFonts.montserrat(
                                              color: inputHintColor,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _toggleNotesSpeechToText,
                                          tooltip: _isListeningNotes
                                              ? 'Stop voice notes'
                                              : 'Start voice notes',
                                          icon: AnimatedBuilder(
                                            animation: _micPulseController!,
                                            builder: (BuildContext context, _) {
                                              final double pulse =
                                                  _isListeningNotes
                                                  ? _micPulseController!.value
                                                  : 0;
                                              final double yOffset =
                                                  _isListeningNotes
                                                  ? -2.2 *
                                                        math.sin(
                                                          pulse *
                                                              math.pi *
                                                              2,
                                                        )
                                                  : 0;
                                              final double ringScale =
                                                  1 + (pulse * 0.24);
                                              final double ringOpacity =
                                                  _isListeningNotes
                                                  ? (0.2 - (pulse * 0.14))
                                                        .clamp(0.0, 1.0)
                                                  : 0.0;
                                              final Color micColor =
                                                  _isSubmitting
                                                  ? inputHintColor
                                                  : (_isListeningNotes
                                                        ? listeningMicColor
                                                        : inputHintColor);

                                              return SizedBox(
                                                width: 30,
                                                height: 30,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    if (_isListeningNotes)
                                                      Transform.scale(
                                                        scale: ringScale,
                                                        child: Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color:
                                                                listeningMicColor
                                                                    .withValues(
                                                                      alpha:
                                                                          ringOpacity,
                                                                    ),
                                                          ),
                                                        ),
                                                      ),
                                                    Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        yOffset,
                                                      ),
                                                      child: Icon(
                                                        Icons.mic_rounded,
                                                        color: micColor,
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            4,
                            horizontalPadding,
                            compactHeight ? 12 : 16,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: submitHeight,
                            decoration: BoxDecoration(
                              gradient: animatedButtonGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton(
                              onPressed: selectedBodyParts.isEmpty
                                  ? null
                                  : _submitDiagnosis,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                alignment: Alignment.center,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                _isSubmitting ? 'Sending...' : 'Get Diagnosis',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: submitFontSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ViewportToggleButton extends StatelessWidget {
  const _ViewportToggleButton({
    required this.label,
    required this.selected,
    required this.isDarkMode,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDarkMode;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color selectedTextColor = isDarkMode
        ? const Color(0xFFEAF1FF)
        : Colors.white;
    final Color unselectedTextColor = isDarkMode
        ? const Color(0xFFB7C3D7)
        : const Color(0xFF4B5563);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Ink(
            height: 36,
            decoration: BoxDecoration(
              gradient: selected ? gradient : null,
              color: selected
                  ? null
                  : (isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  color: selected ? selectedTextColor : unselectedTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
