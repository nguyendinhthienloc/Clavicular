import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class ThreeModelView extends StatefulWidget {
  const ThreeModelView({
    super.key,
    required this.onPartSelected,
  });

  final ValueChanged<String> onPartSelected;

  @override
  State<ThreeModelView> createState() => _ThreeModelViewState();
}

class _ThreeModelViewState extends State<ThreeModelView> {
  static bool _registered = false;
  static const String _viewType = 'three-model-picker-iframe';

  StreamSubscription<html.MessageEvent>? _messageSub;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();

    _messageSub = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is! String) return;

      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic> &&
            decoded['type'] == 'part-selected') {
          final name = (decoded['name'] as String?)?.trim();
          widget.onPartSelected(
            (name == null || name.isEmpty) ? '(unnamed part)' : name,
          );
        }
      } catch (_) {}
    });
  }

  void _registerViewFactory() {
    if (_registered) return;
    _registered = true;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final assetUrl = ui_web.assetManager.getAssetUrl('assets/my_model.glb');

      final iframe = html.IFrameElement()
        ..src = 'model_picker.html?model=${Uri.encodeComponent(assetUrl)}'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      return iframe;
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}