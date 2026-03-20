import 'package:flutter/material.dart';

class ChatViewport extends StatelessWidget {
  const ChatViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('Chat Viewport')),
    );
  }
}