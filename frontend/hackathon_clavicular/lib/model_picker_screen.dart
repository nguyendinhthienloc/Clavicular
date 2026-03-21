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
  static const List<String> _controlGuideLines = <String>[
    'Left click - Select',
    'Shift + left click - Select multiple',
    'Space - Paint',
    'Ctrl/Escape - Unselect',
  ];
  static const List<String> _layerOptions = <String>['Muscle', 'Bone'];

  List<String> selectedBodyParts = <String>[];
  String _selectedViewport = 'chat';
  String _injectedDiagnosisMessage = '';
  int _injectedDiagnosisVersion = 0;
  AnimationController? _gradientController;
  bool _isControlsGuideVisible = false;
  bool _isLayerMenuOpen = false;
  String _selectedLayer = _layerOptions.first;

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

  void _setControlsGuideVisible(bool isVisible) {
    if (_isControlsGuideVisible == isVisible) {
      return;
    }

    setState(() {
      _isControlsGuideVisible = isVisible;
    });
  }

  void _setLayerMenuVisible(bool isVisible) {
    if (_isLayerMenuOpen == isVisible) {
      return;
    }

    setState(() {
      _isLayerMenuOpen = isVisible;
    });
  }

  void _selectLayer(String layer) {
    setState(() {
      _selectedLayer = layer;
      _isLayerMenuOpen = false;
    });
    // Hook to actual filtering when backend support is added.
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

    final Color guideBackground = (isDarkMode
            ? const Color(0xFF111827)
            : Colors.white)
        .withOpacity(isDarkMode ? 0.95 : 0.98);
    final Color guideTextColor =
        isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937);
    final Color guideBorderColor =
        isDarkMode ? Colors.white10 : const Color(0xFFE5E7EB);
    final Color guideIconBackground = isDarkMode
        ? const Color(0xFF0F172A).withOpacity(0.9)
        : Colors.white.withOpacity(0.95);

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
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: Icon(Icons.settings, color: iconColor),
                    onPressed: _showSettingsSheet,
                  ),
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
                          child: Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
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
                                    onSelectionChanged:
                                        (List<String>? partNames) {
                                      final List<String> resolvedParts =
                                          partNames ?? <String>[];
                                      setState(() {
                                        selectedBodyParts = resolvedParts;
                                        if (_hasSelectedBodyPart(
                                          resolvedParts,
                                        )) {
                                          _selectedViewport = 'diagnosis';
                                        } else {
                                          _selectedViewport = 'chat';
                                        }
                                      });
                                    },
                                  ),
                              ),
                            ),
                              Positioned(
                                top: 20,
                                right: 20,
                                child: MouseRegion(
                                  onEnter: (_) => _setLayerMenuVisible(true),
                                  onExit: (_) => _setLayerMenuVisible(false),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.topRight,
                                        child: !_isLayerMenuOpen
                                            ? const SizedBox.shrink()
                                            : Container(
                                                margin:
                                                    const EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: guideBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: guideBorderColor,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isDarkMode
                                                          ? Colors.black
                                                              .withValues(
                                                              alpha: 0.35,
                                                            )
                                                          : const Color(
                                                              0xFF94A3B8,
                                                            ).withValues(
                                                              alpha: 0.25,
                                                            ),
                                                      blurRadius: 18,
                                                      offset: const Offset(0, 10),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Layers',
                                                      style:
                                                          GoogleFonts.montserrat(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: guideTextColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    ..._layerOptions.map(
                                                      (String layer) =>
                                                          GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () =>
                                                            _selectLayer(layer),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 2),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize.min,
                                                            children: [
                                                              Icon(
                                                                layer ==
                                                                        _selectedLayer
                                                                    ? Icons
                                                                        .check_circle
                                                                    : Icons
                                                                        .circle_outlined,
                                                                size: 16,
                                                                color: layer ==
                                                                        _selectedLayer
                                                                    ? iconColor
                                                                    : guideTextColor,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                layer,
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  fontSize: 12,
                                                                  fontWeight: layer ==
                                                                          _selectedLayer
                                                                      ? FontWeight
                                                                          .w600
                                                                      : FontWeight
                                                                          .w500,
                                                                  color:
                                                                      guideTextColor,
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
                                      Container(
                                        decoration: BoxDecoration(
                                          color: guideIconBackground,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: guideBorderColor,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.layers,
                                          color: iconColor,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 20,
                                bottom: 20,
                                child: MouseRegion(
                                  onEnter: (_) =>
                                      _setControlsGuideVisible(true),
                                  onExit: (_) =>
                                      _setControlsGuideVisible(false),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: guideIconBackground,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: guideBorderColor,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.help_outline,
                                          color: iconColor,
                                          size: 20,
                                        ),
                                      ),
                                      AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.bottomLeft,
                                        child: !_isControlsGuideVisible
                                            ? const SizedBox.shrink()
                                            : Container(
                                                margin:
                                                    const EdgeInsets.only(
                                                  left: 12,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: guideBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: guideBorderColor,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isDarkMode
                                                          ? Colors.black
                                                              .withValues(
                                                              alpha: 0.35,
                                                            )
                                                          : const Color(
                                                              0xFF94A3B8,
                                                            ).withValues(
                                                              alpha: 0.25,
                                                            ),
                                                      blurRadius: 18,
                                                      offset:
                                                          const Offset(0, 10),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Controls guide',
                                                      style:
                                                          GoogleFonts.montserrat(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: guideTextColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    ..._controlGuideLines.map(
                                                      (String line) => Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 2),
                                                        child: Text(
                                                          line,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                guideTextColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                                    selectedBodyParts: selectedBodyParts,
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
