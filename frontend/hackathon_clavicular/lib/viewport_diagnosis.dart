import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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
    with SingleTickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();
  late final Dio _dio;
  AnimationController? _gradientController;

  String? _selectedSeverity;
  String? _selectedPainType;
  String? _selectedDuration;
  String? _selectedActivity;
  bool _useCurrentLocation = true;
  bool _isSubmitting = false;
  bool _isLocating = false;
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
    _notesController.dispose();
    _gradientController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _gradientController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

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
    final String viewportValue =
        (widget.selectedViewport == 'Chat' ||
            widget.selectedViewport == 'Diagnosis')
        ? widget.selectedViewport
        : 'Chat';
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
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
                                  selected: viewportValue == 'Chat',
                                  isDarkMode: isDarkMode,
                                  gradient: animatedOutlineGradient,
                                  onTap: () => widget.onViewportChanged('Chat'),
                                ),
                              ),
                              Expanded(
                                child: _ViewportToggleButton(
                                  label: 'Diagnosis',
                                  selected: viewportValue == 'Diagnosis',
                                  isDarkMode: isDarkMode,
                                  gradient: animatedOutlineGradient,
                                  onTap: () =>
                                      widget.onViewportChanged('Diagnosis'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              height: 118,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: animatedOutlineGradient,
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(1.4),
                                decoration: BoxDecoration(
                                  color: composerBackground,
                                  borderRadius: BorderRadius.circular(22.6),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    12,
                                    14,
                                    10,
                                  ),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _notesController,
                                        maxLines: 1,
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
                                      const Spacer(),
                                      const Align(
                                        alignment: Alignment.centerRight,
                                        child: Icon(Icons.graphic_eq),
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Container(
                        width: double.infinity,
                        height: 56,
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
                            _isSubmitting ? 'Sending...' : 'Get diagnosis',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
