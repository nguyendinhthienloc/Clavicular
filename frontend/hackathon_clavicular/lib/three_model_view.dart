import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class ThreeModelView extends StatefulWidget {
  const ThreeModelView({
    super.key,
    this.onSelectionChanged,
    this.onPartSelected,
    required this.isDarkMode,
    required this.modelAssetPath,
    required this.isModelLocked,
  }) : assert(
         onSelectionChanged != null || onPartSelected != null,
         'Provide onSelectionChanged or onPartSelected',
       );

  final ValueChanged<List<String>?>? onSelectionChanged;
  final ValueChanged<String>? onPartSelected;
  final bool isDarkMode;
  final String modelAssetPath;
  final bool isModelLocked;

  @override
  State<ThreeModelView> createState() => _ThreeModelViewState();
}

class _ThreeModelViewState extends State<ThreeModelView> {
  static int _viewTypeCounter = 0;

  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messageSub;
  late String _currentAssetPath;

  @override
  void initState() {
    super.initState();
    _currentAssetPath = widget.modelAssetPath;
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
      final dynamic rawNames = payload['names'];
      List<String> names = <String>[];

      if (rawNames is List) {
        names = rawNames
            .whereType<String>()
            .map((String name) => name.trim())
            .where(
              (String name) => name.isNotEmpty && name != 'Nothing selected',
            )
            .toSet()
            .toList();
      }

      if (names.isEmpty) {
        final dynamic rawName = payload['name'];
        final String singleName = rawName is String ? rawName.trim() : '';
        if (singleName.isNotEmpty && singleName != 'Nothing selected') {
          names = <String>[singleName];
        }
      }

      widget.onSelectionChanged?.call(names);

      final dynamic rawName = payload['name'];
      final String legacyName = rawName is String ? rawName.trim() : '';
      final String fallbackName = names.isEmpty
          ? 'Nothing selected'
          : names.join(', ');
      widget.onPartSelected?.call(
        legacyName.isNotEmpty ? legacyName : fallbackName,
      );
    }
  }

  void _registerViewFactory() {
    final bool initialDarkMode = widget.isDarkMode;
    final String initialAssetPath = _currentAssetPath;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final assetUrl = ui_web.assetManager.getAssetUrl(initialAssetPath);

      final iframe = html.IFrameElement()
        ..src = _buildIframeSrc(assetUrl, initialDarkMode)
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      iframe.onLoad.listen((_) {
        _postThemeMode(widget.isDarkMode);
        _postLockState(widget.isModelLocked);
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

  void _postLockState(bool isLocked) {
    final html.WindowBase? target = _iframe?.contentWindow;
    if (target == null) {
      return;
    }

    final String message = jsonEncode(<String, dynamic>{
      'type': 'lock-state-changed',
      'locked': isLocked,
    });

    target.postMessage(message, '*');
  }

  @override
  void didUpdateWidget(covariant ThreeModelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _postThemeMode(widget.isDarkMode);
    }
    if (oldWidget.isModelLocked != widget.isModelLocked) {
      _postLockState(widget.isModelLocked);
    }
    if (oldWidget.modelAssetPath != widget.modelAssetPath) {
      _currentAssetPath = widget.modelAssetPath;
      _updateModelAsset();
    }
  }

  void _updateModelAsset() {
    final html.IFrameElement? iframe = _iframe;
    if (iframe == null) {
      return;
    }

    final String assetUrl = ui_web.assetManager.getAssetUrl(_currentAssetPath);
    iframe.src = _buildIframeSrc(assetUrl, widget.isDarkMode);
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
