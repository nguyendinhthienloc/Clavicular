import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'config/app_config.dart';
import 'package:flutter_map/flutter_map.dart';

class ViewportChat extends StatefulWidget {
  const ViewportChat({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.selectedViewport,
    required this.onViewportChanged,
    this.selectedBodyParts = const <String>[],
    this.injectedAssistantMessage,
    this.injectedAssistantVersion = 0,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String selectedViewport;
  final ValueChanged<String> onViewportChanged;
  final List<String> selectedBodyParts;
  final String? injectedAssistantMessage;
  final int injectedAssistantVersion;

  @override
  State<ViewportChat> createState() => _ViewportChatState();
}

class _ViewportChatState extends State<ViewportChat>
  with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  late final Dio _dio;
  AnimationController? _gradientController;
  AnimationController? _micPulseController;
  bool _isTyping = false;
  bool _hasSentFirstMessage = false;
  bool _isLoading = false;
  bool _isLoadingMap = false;
  bool _isListening = false;
  bool _hasDiagnosis = false;
  int _lastInjectedAssistantVersion = -1;
  Completer<void>? _resumeCompleter;
  List<String> _conditionNames = <String>[];
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_handleTypingState);
    _dio = Dio();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  void _handleTypingState() {
    final bool typing = _controller.text.trim().isNotEmpty;
    if (typing != _isTyping && !_hasSentFirstMessage) {
      setState(() {
        _isTyping = typing;
      });
    }
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.trim().isEmpty) {
      return;
    }

    final Uri? uri = Uri.tryParse(href.trim());
    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _fetchSourcesFromChat() async {
    if (_isLoading) {
      return;
    }

    if (!_hasDiagnosis) {
      return;
    }

    final List<String> bodyParts = widget.selectedBodyParts
        .map((String value) => value.trim())
        .where(
          (String value) => value.isNotEmpty && value != 'Nothing selected',
        )
        .toList();

    if (bodyParts.isEmpty) {
      setState(() {
        _messages.add(
          const _ChatMessage(
            text:
                'Please select at least one body part before requesting diagnosis.',
            isUser: false,
          ),
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Response<dynamic> sourcesResponse = await _dio
          .post<dynamic>(
            '${AppConfig.apiEndpoint}/ai/sources',
            data: <String, dynamic>{
              'bodyParts': bodyParts,
              'severity': 'Mild',
              'painType': 'sharp',
              'duration': '< 1 week',
              'trigger': 'Rest',
              'lat': null,
              'lng': null,
            },
            options: Options(
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ),
          )
          .timeout(const Duration(seconds: 35));

      final String sourcesMarkdown = _buildSourcesMarkdown(
        sourcesResponse.data,
      );

      setState(() {
        _messages.add(_ChatMessage(text: sourcesMarkdown, isUser: false));
      });
    } on DioException catch (error) {
      setState(() {
        _messages.add(
          _ChatMessage(
            text: 'Sources request failed: ${error.message}',
            isUser: false,
          ),
        );
      });
    } catch (error) {
      setState(() {
        _messages.add(
          _ChatMessage(text: 'Unexpected sources error: $error', isUser: false),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSentFirstMessage = true;
          _isTyping = false;
        });
      }
    }
  }

  String _buildSourcesMarkdown(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return 'No sources found.';
    }

    final dynamic payload = responseData['payload'];
    if (payload is! Map<String, dynamic>) {
      return 'No sources found.';
    }

    final dynamic data = payload['data'];
    if (data is! List || data.isEmpty) {
      return 'No sources found.';
    }

    final List<String> renderedItems = <String>[];
    final Set<String> seenKeys = <String>{};

    for (final dynamic item in data) {
      if (item is Map) {
        final String articleLine = _buildSourceItemLine(item);
        if (articleLine.isEmpty) {
          continue;
        }

        final dynamic idValue = item['id'];
        final dynamic titleValue = item['title'];
        final dynamic urlValue = item['url'];
        final String uniqueKey =
            '${idValue ?? ''}|${titleValue ?? ''}|${urlValue ?? ''}';

        if (seenKeys.contains(uniqueKey)) {
          continue;
        }

        seenKeys.add(uniqueKey);
        renderedItems.add(articleLine);
      }
    }

    if (renderedItems.isEmpty) {
      return 'No sources found.';
    }

    return '### Sources\n${renderedItems.join('\n')}';
  }

  String _buildSourceItemLine(Map<dynamic, dynamic> item) {
    final String title = (item['title'] ?? '').toString().trim();
    final String url = (item['url'] ?? '').toString().trim();

    if (title.isEmpty || url.isEmpty) {
      return '';
    }

    final String safeTitle = title
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]');
    return '- [$safeTitle]($url)';
  }

  String _extractAssistantMessage(dynamic payload) {
    if (payload is String) {
      return payload.trim();
    }

    if (payload is! Map<String, dynamic>) {
      return payload?.toString().trim() ?? '';
    }

    final dynamic textField = payload['text'];
    if (textField is String && textField.trim().isNotEmpty) {
      return textField.trim();
    }

    final dynamic dataField = payload['data'];
    if (dataField is String && dataField.trim().isNotEmpty) {
      return dataField.trim();
    }

    if (dataField is Map<String, dynamic>) {
      final dynamic nestedText = dataField['text'];
      if (nestedText is String && nestedText.trim().isNotEmpty) {
        return nestedText.trim();
      }

      final dynamic nestedData = dataField['data'];
      if (nestedData is Map<String, dynamic>) {
        final dynamic deeplyNestedText = nestedData['text'];
        if (deeplyNestedText is String && deeplyNestedText.trim().isNotEmpty) {
          return deeplyNestedText.trim();
        }
      }
    }

    return '';
  }

  Future<void> _sendMessage() async {
    final bool shouldResetVoiceInput = _isListening;
    if (shouldResetVoiceInput) {
      await _resetSpeechToTextBuffer();
    }

    final String text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    final bool isFirstMessage = _messages.isEmpty;

    setState(() {
      if (isFirstMessage) {
        _hasSentFirstMessage = true;
      }
      _isTyping = false;
      _isLoading = true;
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
    });

    try {
      final Map<String, dynamic> chatPayload = <String, dynamic>{
        'message': text,
      };
      debugPrint('[POST /api/ai/chat] payload: ${jsonEncode(chatPayload)}');

      final Response<dynamic> response = await _dio
          .post<Map<String, dynamic>>(
            '${AppConfig.apiEndpoint}/ai/chat',
            data: chatPayload,
            options: Options(
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ),
          )
          .timeout(const Duration(seconds: 35));

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (response.statusCode == 200) {
          try {
            final Map<String, dynamic> responseData =
                response.data as Map<String, dynamic>;
            final List<String> conditionNames = _extractConditionNames(
              responseData,
            );
            if (conditionNames.isNotEmpty) {
              _conditionNames = conditionNames;
              _hasDiagnosis = true;
            }

            final dynamic payloadField = responseData['payload'];
            final String assistantMessage = _extractAssistantMessage(
              payloadField,
            );

            if (assistantMessage.isEmpty) {
              _messages.add(
                _ChatMessage(
                  text: 'Empty response - received: ${responseData.toString()}',
                  isUser: false,
                ),
              );
            } else {
              _messages.add(
                _ChatMessage(text: assistantMessage, isUser: false),
              );
            }
          } catch (e) {
            _messages.add(
              _ChatMessage(
                text: 'Error parsing response: $e\nRaw: ${response.data}',
                isUser: false,
              ),
            );
          }
        } else {
          _messages.add(
            _ChatMessage(
              text:
                  'Error: Server returned status ${response.statusCode}. ${response.data}',
              isUser: false,
            ),
          );
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        String errorMsg = 'Connection error';
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Request timeout - server took too long to respond';
        } else if (e.response != null) {
          errorMsg = 'Server error: ${e.response?.statusCode} - ${e.message}';
        } else {
          errorMsg = 'Connection error: ${e.message}';
        }
        _messages.add(_ChatMessage(text: errorMsg, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _messages.add(
          _ChatMessage(text: 'Unexpected error: $e', isUser: false),
        );
      });
    }
  }

  Future<void> _toggleSpeechToText() async {
    if (_isListening) {
      await _stopSpeechToText();
      return;
    }

    try {
      final bool isAvailable = await _speechToText.initialize(
        onStatus: (String status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              _micPulseController?.stop();
              _micPulseController?.value = 0;
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (error) {
          if (!mounted) {
            return;
          }
          _micPulseController?.stop();
          _micPulseController?.value = 0;
          setState(() {
            _isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('STT error: ${error.errorMsg}')),
          );
        },
      );

      if (!isAvailable) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available.')),
        );
        return;
      }

      setState(() {
        _isListening = true;
      });
      _micPulseController?.repeat(reverse: true);

      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) {
            return;
          }

          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
            _isTyping = _controller.text.trim().isNotEmpty;
          });
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _micPulseController?.stop();
      _micPulseController?.value = 0;
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start STT: $error')));
    }
  }

  Future<void> _stopSpeechToText() async {
    try {
      await _speechToText.stop();
    } finally {
      _micPulseController?.stop();
      _micPulseController?.value = 0;
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  Future<void> _resetSpeechToTextBuffer() async {
    try {
      await _speechToText.cancel();
    } catch (_) {
      // Ignore reset errors so sending still proceeds.
    } finally {
      _micPulseController?.stop();
      _micPulseController?.value = 0;
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  Future<void> _showLocationPrompt({
    required String title,
    required String message,
    required Future<bool> Function() onOpenSettings,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final bool opened = await onOpenSettings();
                if (opened) {
                  await _waitForAppResume();
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _waitForAppResume() async {
    _resumeCompleter = Completer<void>();
    try {
      await _resumeCompleter!.future.timeout(const Duration(seconds: 45));
    } catch (_) {
      // If resume isn't observed in time, continue with a normal retry path.
    } finally {
      _resumeCompleter = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _resumeCompleter != null &&
        !_resumeCompleter!.isCompleted) {
      _resumeCompleter!.complete();
    }
  }

  Future<_UserLocation?> _resolveCurrentLocationForMap() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationPrompt(
          title: 'Turn on location',
          message:
              'Location services are off. Turn on location services to show nearby places on the map.',
          onOpenSettings: Geolocator.openLocationSettings,
        );
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        await _showLocationPrompt(
          title: 'Location permission needed',
          message:
              'Please allow location access so nearby places can be shown on the map.',
          onOpenSettings: Geolocator.openAppSettings,
        );
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _showLocationPrompt(
          title: 'Permission denied forever',
          message:
              'Location permission is permanently denied. Enable it in app settings to continue.',
          onOpenSettings: Geolocator.openAppSettings,
        );
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          return null;
        }
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return _UserLocation(position.latitude, position.longitude);
    } catch (_) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get your location. Please try again.'),
        ),
      );
      return null;
    }
  }

  List<String> _extractConditionNames(dynamic responseData) {
    if (responseData is String) {
      final List<String> namesFromText = _extractConditionNamesFromText(
        responseData,
      );
      if (namesFromText.isNotEmpty) {
        return namesFromText;
      }
    }

    if (responseData is! Map<String, dynamic>) {
      return const <String>[];
    }

    final List<String> namesFromRoot = _extractConditionNamesFromMap(
      responseData,
    );
    if (namesFromRoot.isNotEmpty) {
      return namesFromRoot;
    }

    final dynamic payload = responseData['payload'];
    if (payload is Map<String, dynamic>) {
      final List<String> namesFromPayload = _extractConditionNamesFromMap(
        payload,
      );
      if (namesFromPayload.isNotEmpty) {
        return namesFromPayload;
      }

      final dynamic payloadData = payload['data'];
      if (payloadData is Map<String, dynamic>) {
        final List<String> namesFromPayloadData = _extractConditionNamesFromMap(
          payloadData,
        );
        if (namesFromPayloadData.isNotEmpty) {
          return namesFromPayloadData;
        }
      }
    }

    final dynamic data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return _extractConditionNamesFromMap(data);
    }

    if (data is String) {
      final List<String> namesFromText = _extractConditionNamesFromText(data);
      if (namesFromText.isNotEmpty) {
        return namesFromText;
      }
    }

    if (payload is String) {
      final List<String> namesFromText = _extractConditionNamesFromText(
        payload,
      );
      if (namesFromText.isNotEmpty) {
        return namesFromText;
      }
    }

    return const <String>[];
  }

  List<String> _extractConditionNamesFromText(String rawText) {
    final String text = rawText.trim();
    if (text.isEmpty) {
      return const <String>[];
    }

    try {
      final dynamic decoded = jsonDecode(text);
      final List<String> names = _extractConditionNames(decoded);
      if (names.isNotEmpty) {
        return names;
      }
    } catch (_) {}

    final RegExp jsonNamePattern = RegExp(r'"name"\s*:\s*"([^"]+)"');
    return jsonNamePattern
        .allMatches(text)
        .map((RegExpMatch match) => (match.group(1) ?? '').trim())
        .where((String name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _fallbackConditionNames() {
    final List<String> selectedBodyParts = widget.selectedBodyParts
        .map((String value) => value.trim())
        .where(
          (String value) => value.isNotEmpty && value != 'Nothing selected',
        )
        .toList();

    if (selectedBodyParts.isNotEmpty) {
      return selectedBodyParts;
    }

    final String prompt = _latestUserPrompt;
    if (prompt.isNotEmpty) {
      return <String>[prompt];
    }

    return const <String>['General clinic'];
  }

  List<String> _extractConditionNamesFromMap(Map<String, dynamic> source) {
    final dynamic conditions = source['conditions'];
    if (conditions is! List) {
      return const <String>[];
    }

    return conditions
        .whereType<Map>()
        .map((Map item) => (item['name'] ?? '').toString().trim())
        .where((String name) => name.isNotEmpty)
        .toList();
  }

  String get _latestUserPrompt {
    for (int index = _messages.length - 1; index >= 0; index--) {
      final _ChatMessage message = _messages[index];
      if (message.isUser && message.text.trim().isNotEmpty) {
        return message.text.trim();
      }
    }
    return '';
  }

  List<_PlacePoint> _extractPlaces(dynamic responseData) {
    if (responseData is List) {
      return _extractPlacesFromList(responseData);
    }

    if (responseData is! Map<String, dynamic>) {
      return const <_PlacePoint>[];
    }

    final List<_PlacePoint> directPlaces = _extractPlacesFromMap(responseData);
    if (directPlaces.isNotEmpty) {
      return directPlaces;
    }

    final dynamic payload = responseData['payload'];
    if (payload is Map<String, dynamic>) {
      final List<_PlacePoint> payloadPlaces = _extractPlacesFromMap(payload);
      if (payloadPlaces.isNotEmpty) {
        return payloadPlaces;
      }

      final dynamic data = payload['data'];
      if (data is List) {
        final List<_PlacePoint> payloadDataPlaces = _extractPlacesFromList(
          data,
        );
        if (payloadDataPlaces.isNotEmpty) {
          return payloadDataPlaces;
        }
      }
      if (data is Map<String, dynamic>) {
        final List<_PlacePoint> dataPlaces = _extractPlacesFromMap(data);
        if (dataPlaces.isNotEmpty) {
          return dataPlaces;
        }
      }
    }

    final dynamic data = responseData['data'];
    if (data is List) {
      final List<_PlacePoint> dataPlaces = _extractPlacesFromList(data);
      if (dataPlaces.isNotEmpty) {
        return dataPlaces;
      }
    }

    if (data is Map<String, dynamic>) {
      final List<_PlacePoint> dataPlaces = _extractPlacesFromMap(data);
      if (dataPlaces.isNotEmpty) {
        return dataPlaces;
      }
    }

    final dynamic clinics = responseData['clinics'];
    if (clinics is List) {
      return _extractPlacesFromList(clinics);
    }

    return const <_PlacePoint>[];
  }

  List<_PlacePoint> _extractPlacesFromMap(Map<String, dynamic> source) {
    final dynamic places = source['places'];
    if (places is List) {
      final List<_PlacePoint> placeList = _extractPlacesFromList(places);
      if (placeList.isNotEmpty) {
        return placeList;
      }
    }

    final dynamic clinics = source['clinics'];
    if (clinics is List) {
      return _extractPlacesFromList(clinics);
    }

    return const <_PlacePoint>[];
  }

  List<_PlacePoint> _extractPlacesFromList(List<dynamic> rawItems) {
    final List<_PlacePoint> places = <_PlacePoint>[];

    for (int index = 0; index < rawItems.length; index++) {
      final dynamic raw = rawItems[index];
      if (raw is! Map) {
        continue;
      }

      _debugPrintRawPlaceCoordinates(raw, index);

      final String name = (raw['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        continue;
      }

      double? lat = _tryParseDouble(raw['lat'] ?? raw['latitude']);
      double? lng = _tryParseDouble(
        raw['lng'] ?? raw['lon'] ?? raw['longitude'],
      );

      if (lat == null || lng == null) {
        final dynamic geocodes = raw['geocodes'];
        if (geocodes is Map) {
          final dynamic main = geocodes['main'];
          if (main is Map) {
            lat = lat ?? _tryParseDouble(main['lat'] ?? main['latitude']);
            lng = lng ?? _tryParseDouble(main['lng'] ?? main['longitude']);
          }
        }
      }

      if (lat == null || lng == null) {
        final dynamic position = raw['position'];
        if (position is Map) {
          lat = lat ?? _tryParseDouble(position['lat'] ?? position['latitude']);
          lng =
              lng ?? _tryParseDouble(position['lng'] ?? position['longitude']);
        }
      }

      if (lat == null || lng == null) {
        final String mapsUrl =
            (raw['maps_url'] ?? raw['mapsUrl'] ?? raw['google_maps_url'] ?? '')
                .toString();
        final _UserLocation? parsed = _parseLocationFromMapsUrl(mapsUrl);
        if (parsed != null) {
          lat = parsed.lat;
          lng = parsed.lng;
        }
      }

      if (lat == null || lng == null) {
        continue;
      }

      places.add(
        _PlacePoint(
          name: name,
          lat: lat,
          lng: lng,
          address: (raw['address'] ?? '').toString().trim(),
        ),
      );
    }

    return places;
  }

  void _debugPrintRawPlaceCoordinates(Map raw, int index) {
    final dynamic latCandidate = raw['lat'] ?? raw['latitude'];
    final dynamic lngCandidate = raw['lng'] ?? raw['lon'] ?? raw['longitude'];

    dynamic geocodesLat;
    dynamic geocodesLng;
    final dynamic geocodes = raw['geocodes'];
    if (geocodes is Map) {
      final dynamic main = geocodes['main'];
      if (main is Map) {
        geocodesLat = main['lat'] ?? main['latitude'];
        geocodesLng = main['lng'] ?? main['longitude'];
      }
    }

    dynamic positionLat;
    dynamic positionLng;
    final dynamic position = raw['position'];
    if (position is Map) {
      positionLat = position['lat'] ?? position['latitude'];
      positionLng = position['lng'] ?? position['longitude'];
    }

    final String mapsUrl =
        (raw['maps_url'] ?? raw['mapsUrl'] ?? raw['google_maps_url'] ?? '')
            .toString();

    debugPrint(
      '[POST /api/ai/clinics][raw#$index] lat=$latCandidate lng=$lngCandidate geocodes.lat=$geocodesLat geocodes.lng=$geocodesLng position.lat=$positionLat position.lng=$positionLng mapsUrl=$mapsUrl',
    );
  }

  double? _tryParseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  _UserLocation? _parseLocationFromMapsUrl(String mapsUrl) {
    if (mapsUrl.trim().isEmpty) {
      return null;
    }

    final Uri? uri = Uri.tryParse(mapsUrl);
    if (uri == null) {
      return null;
    }

    final String query = uri.queryParameters['query'] ?? '';
    if (query.isEmpty) {
      return null;
    }

    final List<String> coordinates = query.split(',');
    if (coordinates.length < 2) {
      return null;
    }

    final double? lat = double.tryParse(coordinates[0].trim());
    final double? lng = double.tryParse(coordinates[1].trim());
    if (lat == null || lng == null) {
      return null;
    }

    return _UserLocation(lat, lng);
  }

  void _debugPrintPlaces(String source, List<_PlacePoint> places) {
    if (places.isEmpty) {
      debugPrint('[$source] parsed places: []');
      return;
    }

    for (final _PlacePoint place in places) {
      debugPrint(
        '[$source] ${place.name} | lat=${place.lat} | lng=${place.lng}',
      );
    }
  }

  Future<void> showMap() async {
    if (_isLoading || _isLoadingMap) {
      return;
    }

    setState(() {
      _isLoadingMap = true;
    });

    try {
      final _UserLocation? location = await _resolveCurrentLocationForMap();
      if (location == null) {
        return;
      }

      List<String> names = _conditionNames;
      if (names.isEmpty) {
        names = _fallbackConditionNames();
      }

      _conditionNames = names;

      final String normalizedPrimaryCondition = names.first
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final Map<String, dynamic> mapPostPayload = <String, dynamic>{
        'conditionName': normalizedPrimaryCondition,
        'lat': 10.822,
        'lng': 106.6257,
      };
      debugPrint(
        '[POST /api/ai/clinics] payload: ${jsonEncode(mapPostPayload)}',
      );

      List<_PlacePoint> places = const <_PlacePoint>[];

      try {
        final Response<dynamic> getProbeResponse = await _dio
            .post<dynamic>(
              '${AppConfig.apiEndpoint}/ai/clinics',
              data: mapPostPayload,
              options: Options(receiveTimeout: const Duration(seconds: 30)),
            )
            .timeout(const Duration(seconds: 35));
        debugPrint(
          '[POST /api/ai/clinics] response: ${jsonEncode(getProbeResponse.data)}',
        );

        places = _extractPlaces(getProbeResponse.data);
        _debugPrintPlaces('POST /api/ai/clinics', places);
      } catch (error) {
        debugPrint('[POST /api/ai/clinics] failed: $error');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        if (places.isEmpty) {
          _messages.add(
            const _ChatMessage(
              text: 'No nearby places with coordinates were returned.',
              isUser: false,
            ),
          );
        } else {
          _messages.add(
            _ChatMessage(text: 'Nearby places', isUser: false, places: places),
          );
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(
          _ChatMessage(text: 'Map request failed: $error', isUser: false),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMap = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    WidgetsBinding.instance.removeObserver(this);
    _micPulseController?.dispose();
    _controller.removeListener(_handleTypingState);
    _controller.dispose();
    _gradientController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ViewportChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.injectedAssistantVersion != _lastInjectedAssistantVersion) {
      final String text = (widget.injectedAssistantMessage ?? '').trim();
      if (text.isNotEmpty) {
        setState(() {
          _messages.add(_ChatMessage(text: text, isUser: false));
          _hasSentFirstMessage = true;
          _isTyping = false;
          _hasDiagnosis = true;
        });
      }
      _lastInjectedAssistantVersion = widget.injectedAssistantVersion;
    }
  }

  @override
  Widget build(BuildContext context) {
    _gradientController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _micPulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final bool isDarkMode = widget.isDarkMode;
    final bool hasMessages = _messages.isNotEmpty;
    final Color viewportBackground = isDarkMode
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF4F6F8);
    final Color viewportBorder = isDarkMode
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFD4D9E0);
    final Color bubbleUser = isDarkMode
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE8EDF5);
    final Color bubbleAssistant = isDarkMode
        ? const Color(0xFF262626)
        : const Color(0xFFFFFFFF);
    final Color bubbleBorder = isDarkMode
        ? const Color(0xFF3B3B3B)
        : const Color(0xFFD3D8E0);
    final Color bodyTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF1F2937);
    final Color heroTextColor = isDarkMode
        ? const Color(0xFFE4E0D8)
        : const Color(0xFF374151);
    final Color composerBackground = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFFFFFFF);
    final Color inputTextColor = isDarkMode
        ? const Color(0xFFE3E3E3)
        : const Color(0xFF111827);
    final Color inputHintColor = isDarkMode
        ? const Color(0xFF9C9C9C)
        : const Color(0xFF6B7280);
    final Color controlIconColor = isDarkMode
        ? const Color(0xFFBEBEBE)
        : const Color(0xFF4B5563);
    final Color disabledIconColor = isDarkMode
        ? const Color(0xFF6E6E6E)
        : const Color(0xFF9CA3AF);
    final String normalizedViewport = widget.selectedViewport
      .trim()
      .toLowerCase();
    final String viewportValue =
      (normalizedViewport == 'chat' || normalizedViewport == 'diagnosis')
      ? normalizedViewport
      : 'chat';
    final Color listeningMicColor = isDarkMode
      ? const Color(0xFF60A5FA)
      : const Color(0xFF2563EB);
    final List<Color> outlineColors = isDarkMode
        ? const [Color(0xFF60A5FA), Color(0xFF1D4ED8)]
        : const [Color(0xFF93C5FD), Color(0xFF2563EB)];

    return AnimatedBuilder(
      animation: _gradientController!,
      builder: (context, child) {
        final double shift = -1 + (_gradientController!.value * 2);
        final LinearGradient animatedOutlineGradient = LinearGradient(
          begin: Alignment(-1 + shift, 0),
          end: Alignment(1 + shift, 0),
          colors: outlineColors,
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              gradient: animatedOutlineGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.6),
                child: Container(
                  decoration: BoxDecoration(
                    color: viewportBackground,
                    border: Border.all(color: viewportBorder),
                    borderRadius: BorderRadius.circular(8.6),
                  ),
                  child: Material(
                    color: viewportBackground,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: composerBackground,
                                border: Border.all(color: viewportBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ViewportToggleButton(
                                      label: 'Chat',
                                      selected: viewportValue == 'chat',
                                      isDarkMode: isDarkMode,
                                      gradient: animatedOutlineGradient,
                                      onTap: () =>
                                          widget.onViewportChanged('chat'),
                                    ),
                                  ),
                                  Expanded(
                                    child: _ViewportToggleButton(
                                      label: 'Diagnosis',
                                      selected: viewportValue == 'diagnosis',
                                      isDarkMode: isDarkMode,
                                      gradient: animatedOutlineGradient,
                                      onTap: () =>
                                          widget.onViewportChanged('diagnosis'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              if (hasMessages)
                                ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount:
                                      _messages.length + (_isLoading ? 1 : 0),
                                  itemBuilder: (BuildContext context, int index) {
                                    if (_isLoading &&
                                        index == _messages.length) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          constraints: const BoxConstraints(
                                            maxWidth: 420,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bubbleAssistant,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: bubbleBorder,
                                            ),
                                          ),
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    bodyTextColor,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final _ChatMessage message =
                                        _messages[index];

                                    return Align(
                                      alignment: message.isUser
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        constraints: const BoxConstraints(
                                          maxWidth: 420,
                                        ),
                                        decoration: BoxDecoration(
                                          color: message.isUser
                                              ? bubbleUser
                                              : bubbleAssistant,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: bubbleBorder,
                                          ),
                                        ),
                                        child: message.isUser
                                            ? Text(
                                                message.text,
                                                style: GoogleFonts.montserrat(
                                                  color: bodyTextColor,
                                                ),
                                              )
                                            : (message.places.isNotEmpty
                                                  ? Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (message.text
                                                            .trim()
                                                            .isNotEmpty)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 8,
                                                                ),
                                                            child: Text(
                                                              message.text,
                                                              style: GoogleFonts.montserrat(
                                                                color:
                                                                    bodyTextColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ...message.places.map(
                                                          (
                                                            _PlacePoint place,
                                                          ) => Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 12,
                                                                ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  place.name,
                                                                  style: GoogleFonts.montserrat(
                                                                    color:
                                                                        bodyTextColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                ),
                                                                if (place
                                                                    .address
                                                                    .isNotEmpty)
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets.only(
                                                                          top:
                                                                              2,
                                                                          bottom:
                                                                              6,
                                                                        ),
                                                                    child: Text(
                                                                      place
                                                                          .address,
                                                                      style: GoogleFonts.montserrat(
                                                                        color: bodyTextColor.withValues(
                                                                          alpha:
                                                                              0.78,
                                                                        ),
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                SizedBox(
                                                                  height: 180,
                                                                  child: ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                    child: FlutterMap(
                                                                      options: MapOptions(
                                                                        initialCenter: LatLng(
                                                                          place
                                                                              .lat,
                                                                          place
                                                                              .lng,
                                                                        ),
                                                                        initialZoom:
                                                                            15,
                                                                      ),
                                                                      children: [
                                                                        TileLayer(
                                                                          urlTemplate:
                                                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                                          userAgentPackageName:
                                                                              'com.hackathon.clavicular',
                                                                        ),
                                                                        MarkerLayer(
                                                                          markers: [
                                                                            Marker(
                                                                              point: LatLng(
                                                                                place.lat,
                                                                                place.lng,
                                                                              ),
                                                                              width: 36,
                                                                              height: 36,
                                                                              child: const Icon(
                                                                                Icons.location_on,
                                                                                color: Colors.red,
                                                                                size: 32,
                                                                              ),
                                                                            ),
                                                                          ],
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
                                                    )
                                                  : MarkdownBody(
                                                      data: message.text,
                                                      selectable: true,
                                                      onTapLink:
                                                          (
                                                            String text,
                                                            String? href,
                                                            String title,
                                                          ) {
                                                            _openLink(href);
                                                          },
                                                      styleSheet: MarkdownStyleSheet(
                                                        p: GoogleFonts.montserrat(
                                                          color: bodyTextColor,
                                                          fontSize: 14,
                                                        ),
                                                        a: GoogleFonts.montserrat(
                                                          color: Colors.blue,
                                                          fontSize: 14,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                        h1: GoogleFonts.montserrat(
                                                          color: bodyTextColor,
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                        h2: GoogleFonts.montserrat(
                                                          color: bodyTextColor,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                        h3: GoogleFonts.montserrat(
                                                          color: bodyTextColor,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                        listBullet:
                                                            GoogleFonts.montserrat(
                                                              color:
                                                                  bodyTextColor,
                                                            ),
                                                        code:
                                                            GoogleFonts.robotoMono(
                                                              color:
                                                                  bodyTextColor,
                                                              fontSize: 13,
                                                            ),
                                                        codeblockDecoration:
                                                            BoxDecoration(
                                                              color: isDarkMode
                                                                  ? const Color(
                                                                      0xFF1B1B1B,
                                                                    )
                                                                  : const Color(
                                                                      0xFFF1F5F9,
                                                                    ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                      ),
                                                    )),
                                      ),
                                    );
                                  },
                                ),
                              if (!hasMessages)
                                IgnorePointer(
                                  child: Center(
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      opacity: _isTyping ? 0.35 : 0.5,
                                      child: Text(
                                        'Start a conversation',
                                        style: GoogleFonts.montserrat(
                                          color: heroTextColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    color: composerBackground,
                                    border: Border.all(color: viewportBorder),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      12,
                                      12,
                                      12,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed:
                                              (_hasDiagnosis && !_isLoading)
                                              ? _fetchSourcesFromChat
                                              : null,
                                          icon: Icon(
                                            Icons.link,
                                            color:
                                                (_hasDiagnosis && !_isLoading)
                                                ? controlIconColor
                                                : disabledIconColor,
                                            size: 30,
                                          ),
                                          tooltip: _hasDiagnosis
                                              ? (_isLoading
                                                    ? 'Loading sources...'
                                                    : 'Find source from diagnosis')
                                              : 'Run diagnosis first',
                                        ),
                                        IconButton(
                                          onPressed:
                                              (!_isLoading && !_isLoadingMap)
                                              ? showMap
                                              : null,
                                          icon: Icon(
                                            Icons.map_outlined,
                                            color:
                                                (!_isLoading && !_isLoadingMap)
                                                ? controlIconColor
                                                : disabledIconColor,
                                            size: 30,
                                          ),
                                          tooltip: _isLoadingMap
                                              ? 'Loading map...'
                                              : 'Show nearby clinics on map',
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _controller,
                                            maxLines: 1,
                                            textInputAction:
                                                TextInputAction.send,
                                            style: GoogleFonts.montserrat(
                                              color: inputTextColor,
                                              fontSize: 16,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'How can I help you today?',
                                              hintStyle: GoogleFonts.montserrat(
                                                color: inputHintColor,
                                                fontSize: 18,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                            onSubmitted: (_) => _sendMessage(),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          onPressed: !_isLoading
                                              ? _toggleSpeechToText
                                              : null,
                                          icon: AnimatedBuilder(
                                            animation: _micPulseController!,
                                            builder: (BuildContext context, _) {
                                              final double pulse = _isListening
                                                  ? _micPulseController!.value
                                                  : 0;
                                              final double yOffset = _isListening
                                                  ? -2.4 *
                                                        math.sin(
                                                          pulse *
                                                              math.pi *
                                                              2,
                                                        )
                                                  : 0;
                                              final double ringScale =
                                                  1 + (pulse * 0.26);
                                              final double ringOpacity =
                                                  _isListening
                                                  ? (0.22 - (pulse * 0.16))
                                                        .clamp(0.0, 1.0)
                                                  : 0.0;
                                              final Color micColor = !_isLoading
                                                  ? (_isListening
                                                        ? listeningMicColor
                                                        : controlIconColor)
                                                  : disabledIconColor;

                                              return SizedBox(
                                                width: 30,
                                                height: 30,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    if (_isListening)
                                                      Transform.scale(
                                                        scale: ringScale,
                                                        child: Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color:
                                                                listeningMicColor
                                                                    .withValues(
                                                                      alpha:
                                                                          ringOpacity,
                                                                    ),
                                                          ),
                                                        ),
                                                      ),
                                                    Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        yOffset,
                                                      ),
                                                      child: Icon(
                                                        Icons.mic_rounded,
                                                        color: micColor,
                                                        size: 25,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          tooltip: _isListening
                                              ? 'Stop voice input'
                                              : 'Start voice input',
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: _sendMessage,
                                          icon: ShaderMask(
                                            shaderCallback: (Rect bounds) {
                                              return animatedOutlineGradient
                                                  .createShader(bounds);
                                            },
                                            blendMode: BlendMode.srcIn,
                                            child: const Icon(
                                              Icons.send_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ViewportToggleButton extends StatelessWidget {
  const _ViewportToggleButton({
    required this.label,
    required this.selected,
    required this.isDarkMode,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDarkMode;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color selectedTextColor = isDarkMode
        ? const Color(0xFFEAF1FF)
        : Colors.white;
    final Color unselectedTextColor = isDarkMode
        ? const Color(0xFFB7C3D7)
        : const Color(0xFF4B5563);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Ink(
            height: 36,
            decoration: BoxDecoration(
              gradient: selected ? gradient : null,
              color: selected
                  ? null
                  : (isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  color: selected ? selectedTextColor : unselectedTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.places = const <_PlacePoint>[],
  });

  final String text;
  final bool isUser;
  final List<_PlacePoint> places;
}

class _UserLocation {
  const _UserLocation(this.lat, this.lng);

  final double lat;
  final double lng;
}

class _PlacePoint {
  const _PlacePoint({
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
  });

  final String name;
  final double lat;
  final double lng;
  final String address;
}
