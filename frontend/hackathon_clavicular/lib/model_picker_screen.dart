import 'package:flutter/material.dart';
import 'three_model_view.dart';
import 'viewport_chat.dart';

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

class _ModelPickerScreenState extends State<ModelPickerScreen> {
  String selectedPart = 'Nothing selected';

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.isDarkMode;
    final Color backgroundColor =
        isDarkMode ? const Color(0xFF0E1117) : const Color(0xFFF4F6F8);
    final Color sidebarColor =
        isDarkMode ? const Color(0xFF161B25) : Colors.white;
    final Color iconColor =
        isDarkMode ? Colors.white : const Color(0xFF1F2933);
    final Color frameColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFD4D9E0);
    final Color frameBackground =
        isDarkMode ? const Color(0xFF1F1F1F) : const Color(0xFFF4F6F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          Container(
            width: 80,
            color: sidebarColor,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(Icons.home, color: iconColor),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.search, color: iconColor),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: iconColor),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: frameBackground,
                        border: Border.all(color: frameColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ThreeModelView(
                        isDarkMode: isDarkMode,
                        onPartSelected: (partName) {
                          setState(() {
                            selectedPart = partName;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ViewportChat(
                      isDarkMode: isDarkMode,
                      onThemeChanged: widget.onThemeChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
