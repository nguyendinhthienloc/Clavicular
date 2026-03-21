import 'package:flutter/material.dart';
import 'package:hackathon_clavicular/viewport_model.dart';
import 'package:hackathon_clavicular/viewport_chat.dart';
import 'package:hackathon_clavicular/config/app_config.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isDarkMode = true;

  void _showSettingsMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 12),
              const Text('Theme', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 16),
              Switch(
                value: _isDarkMode,
                onChanged: (bool value) {
                  setState(() {
                    _isDarkMode = value;
                    appConfig.isDarkMode = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      body: Row(
        children: [
          Container(
            width: 80,
            color: Colors.grey.shade800,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => _showSettingsMenu(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: const ViewportModel()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ViewportChat(
                      isDarkMode: _isDarkMode,
                      onThemeChanged: (bool value) {
                        setState(() {
                          _isDarkMode = value;
                          appConfig.isDarkMode = value;
                        });
                      },
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
