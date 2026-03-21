import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class ThreeModelView extends StatefulWidget {
  const ThreeModelView({
    super.key,
    required this.onPartSelected,
    required this.isDarkMode,
  });

  final ValueChanged<String> onPartSelected;
  final bool isDarkMode;

  @override
  State<ThreeModelView> createState() => _ThreeModelViewState();
}

class _ThreeModelViewState extends State<ThreeModelView> {
  static int _viewTypeCounter = 0;

  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messageSub;

  @override
  void initState() {
    super.initState();
    _viewType = 'three-model-picker-iframe-${_viewTypeCounter++}';
    _registerViewFactory();

    _messageSub = html.window.onMessage.listen(_handleIncomingMessage);
  }

  void _handleIncomingMessage(html.MessageEvent event) {
    final dynamic rawData = event.data;
    dynamic payload = rawData;

    if (rawData is String) {
      try {
        payload = jsonDecode(rawData);
      } catch (_) {
        return;
      }
    }

    if (payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['type'] == 'part-selected') {
      final dynamic rawName = payload['name'];
      final String name = rawName is String ? rawName.trim() : '';
      widget.onPartSelected(name.isEmpty ? '(unnamed part)' : name);
    }
  }

  void _registerViewFactory() {
    final bool initialDarkMode = widget.isDarkMode;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final assetUrl = ui_web.assetManager.getAssetUrl('assets/my_model.glb');

      final iframe = html.IFrameElement()
        ..src = _buildIframeSrc(assetUrl, initialDarkMode)
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      iframe.onLoad.listen((_) {
        _postThemeMode(widget.isDarkMode);
      });

      _iframe = iframe;
      return iframe;
    });
  }

  String _buildIframeSrc(String assetUrl, bool isDarkMode) {
    final String theme = isDarkMode ? 'dark' : 'light';
    final String encodedModel = Uri.encodeComponent(assetUrl);
    return 'model_picker.html?model=$encodedModel&theme=$theme';
  }

  void _postThemeMode(bool isDarkMode) {
    final html.WindowBase? target = _iframe?.contentWindow;
    if (target == null) {
      return;
    }

    final String message = jsonEncode(<String, dynamic>{
      'type': 'theme-changed',
      'mode': isDarkMode ? 'dark' : 'light',
    });

    target.postMessage(message, '*');
  }

  @override
  void didUpdateWidget(covariant ThreeModelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _postThemeMode(widget.isDarkMode);
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _iframe = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
