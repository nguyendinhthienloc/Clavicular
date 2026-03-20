import 'package:flutter/material.dart';
import 'package:hackathon_clavicular/viewport_model.dart';
import 'package:hackathon_clavicular/viewport_chat.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
                  onPressed: () {},
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
                  Expanded(child: const ViewportChat()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
