import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ViewportModel extends StatelessWidget {
  const ViewportModel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const ModelViewer(
        src: 'assets/my_model.glb',
        alt: '3D model',
        autoRotate: true,
        cameraControls: true,
        disableZoom: false,
        backgroundColor: Color(0xFFEFEFEF),
      ),
    );
  }
}
