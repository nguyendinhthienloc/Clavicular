import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

  String _selectedSeverity = 'Mild';
  String _selectedPainType = 'sharp';
  String _selectedDuration = '< 1 week';
  String _selectedActivity = 'Rest';
  bool _isSubmitting = false;

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

  Future<void> _submitDiagnosis() async {
    final List<String> bodyParts = _resolvedSelectedBodyParts;
    if (_isSubmitting || bodyParts.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Response<dynamic> response = await _dio
          .post<dynamic>(
            '${AppConfig.apiEndpoint}/ai/diagnose',
            data: <String, dynamic>{
              'bodyParts': bodyParts,
              'severity': _selectedSeverity,
              'painType': _selectedPainType,
              'duration': _selectedDuration,
              'trigger': _selectedActivity,
              'lat': null,
              'lng': null,
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
        if (payload is Map<String, dynamic>) {
          final dynamic dataField = payload['data'];
          if (dataField is String && dataField.trim().isNotEmpty) {
            message = dataField;
          } else if (dataField != null) {
            message = dataField.toString();
          }
        } else if (payload is String && payload.trim().isNotEmpty) {
          message = payload;
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
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
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
    final Color dropdownText = isDarkMode
        ? const Color(0xFFEAF1FF)
        : Colors.white;
    final String viewportValue =
        (widget.selectedViewport == 'chat' ||
            widget.selectedViewport == 'diagnosis')
        ? widget.selectedViewport
        : 'chat';
    final List<String> selectedBodyParts = _resolvedSelectedBodyParts;
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
                            gradient: animatedOutlineGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: viewportValue,
                                iconEnabledColor: dropdownText,
                                dropdownColor: isDarkMode
                                    ? const Color(0xFF0E1B38)
                                    : const Color(0xFF2563EB),
                                style: GoogleFonts.montserrat(
                                  color: dropdownText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'chat',
                                    child: Text('chat'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'diagnosis',
                                    child: Text('diagnosis'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  widget.onViewportChanged(value);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: selectedBodyParts.isEmpty
                                  ? 'Nothing selected'
                                  : selectedBodyParts.join(', '),
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
                                  value: selectedBodyParts.isEmpty
                                      ? 'Nothing selected'
                                      : selectedBodyParts.join(', '),
                                  child: Text(
                                    selectedBodyParts.isEmpty
                                        ? 'Nothing selected'
                                        : selectedBodyParts.join(', '),
                                  ),
                                ),
                              ],
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedSeverity,
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
                              value: _selectedPainType,
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
                              value: _selectedDuration,
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
                              value: _selectedActivity,
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
                      child: Center(
                        child: Container(
                          width: 280,
                          height: 60,
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
                            child: Center(
                              child: Text(
                                _isSubmitting ? 'sending...' : 'get diagnosis',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
