import "package:flutter/material.dart";

class HumanModelViewport extends StatelessWidget {
  const HumanModelViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('Human Model Viewport')),
    );
  }
}