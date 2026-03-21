import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'three_model_view.dart';
import 'viewport_chat.dart';
import 'viewport_diagnosis.dart';

class ModelPickerScreen extends StatefulWidget {
  const ModelPickerScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<ModelPickerScreen> createState() => _ModelPickerScreenState();
}

class _ModelPickerScreenState extends State<ModelPickerScreen>
    with SingleTickerProviderStateMixin {
  List<String> selectedBodyParts = <String>[];
  String _selectedViewport = 'chat';
  String _injectedDiagnosisMessage = '';
  int _injectedDiagnosisVersion = 0;
  AnimationController? _gradientController;

  bool _hasSelectedBodyPart(List<String>? partNames) {
    return (partNames ?? const <String>[]).isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController?.dispose();
    super.dispose();
  }

  void _showSettingsSheet() {
    final bool isDarkMode = widget.isDarkMode;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDarkMode
          ? const Color(0xFF1F1F1F)
          : const Color(0xFFFFFFFF),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: isDarkMode
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF111827),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Theme',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: isDarkMode,
                      onChanged: (bool value) {
                        widget.onThemeChanged(value);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _gradientController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    final bool isDarkMode = widget.isDarkMode;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF0A0E15)
        : const Color(0xFFE9EEF7);
    final Color sidebarColor = isDarkMode
        ? const Color(0xFF161B25)
        : Colors.white;
    final Color iconColor = isDarkMode ? Colors.white : const Color(0xFF1F2933);
    final Color frameColor = isDarkMode
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFD4D9E0);
    final Color frameBackground = isDarkMode
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF4F6F8);
    final List<Color> outlineColors = isDarkMode
        ? const [Color(0xFF60A5FA), Color(0xFF1D4ED8)]
        : const [Color(0xFF93C5FD), Color(0xFF2563EB)];
    final List<BoxShadow> viewportShadow = [
      BoxShadow(
        color: isDarkMode
            ? Colors.black.withValues(alpha: 0.55)
            : const Color(0xFF1F2937).withValues(alpha: 0.18),
        blurRadius: 22,
        spreadRadius: 1,
        offset: const Offset(0, 10),
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          Container(
            width: 80,
            color: sidebarColor,
            child: Column(
              children: [
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.settings, color: iconColor),
                  onPressed: _showSettingsSheet,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _gradientController!,
                builder: (context, child) {
                  final double shift = -1 + (_gradientController!.value * 2);
                  final LinearGradient animatedOutlineGradient = LinearGradient(
                    begin: Alignment(-1 + shift, 0),
                    end: Alignment(1 + shift, 0),
                    colors: outlineColors,
                  );
                  return Row(
                    children: [
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, -4),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: animatedOutlineGradient,
                              boxShadow: viewportShadow,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(1.4),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: frameBackground,
                                border: Border.all(color: frameColor),
                                borderRadius: BorderRadius.circular(14.6),
                              ),
                              child: ThreeModelView(
                                isDarkMode: isDarkMode,
                                onSelectionChanged: (List<String>? partNames) {
                                  final List<String> resolvedParts =
                                      partNames ?? <String>[];
                                  setState(() {
                                    selectedBodyParts = resolvedParts;
                                    if (_hasSelectedBodyPart(resolvedParts)) {
                                      _selectedViewport = 'diagnosis';
                                    } else {
                                      _selectedViewport = 'chat';
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, -4),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: viewportShadow,
                            ),
                            child: _selectedViewport == 'diagnosis'
                                ? ViewportDiagnosis(
                                    isDarkMode: isDarkMode,
                                    selectedBodyParts: selectedBodyParts,
                                    selectedViewport: _selectedViewport,
                                    onViewportChanged: (String value) {
                                      setState(() {
                                        _selectedViewport = value;
                                      });
                                    },
                                    onDiagnosisReady: (String message) {
                                      setState(() {
                                        _injectedDiagnosisMessage = message;
                                        _injectedDiagnosisVersion++;
                                        _selectedViewport = 'chat';
                                      });
                                    },
                                  )
                                : ViewportChat(
                                    isDarkMode: isDarkMode,
                                    onThemeChanged: widget.onThemeChanged,
                                    selectedViewport: _selectedViewport,
                                    injectedAssistantMessage:
                                        _injectedDiagnosisMessage,
                                    injectedAssistantVersion:
                                        _injectedDiagnosisVersion,
                                    onViewportChanged: (String value) {
                                      setState(() {
                                        _selectedViewport = value;
                                      });
                                    },
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
        ],
      ),
    );
  }
}
