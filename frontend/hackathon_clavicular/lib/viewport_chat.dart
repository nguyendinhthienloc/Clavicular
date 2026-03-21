import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config/app_config.dart';

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
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  late final Dio _dio;
  AnimationController? _gradientController;
  bool _isTyping = false;
  bool _hasSentFirstMessage = false;
  bool _isLoading = false;
  bool _hasDiagnosis = false;
  int _lastInjectedAssistantVersion = -1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTypingState);
    _dio = Dio();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasSentFirstMessage = true;
        _isTyping = false;
      });
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

    final String safeTitle = title.replaceAll('[', r'\[').replaceAll(']', r'\]');
    return '- [$safeTitle]($url)';
  }

  Future<void> _sendMessage() async {
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
      final Response<dynamic> response = await _dio
          .post<Map<String, dynamic>>(
            AppConfig.aiApiTunnelValue,
            data: <String, dynamic>{'prompt': text},
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

            final dynamic dataField = responseData['payload'];
            String assistantMessage = '';

            if (dataField is String) {
              assistantMessage = dataField;
            } else if (dataField is Map<String, dynamic>) {
              assistantMessage = dataField['data'] ?? '';
            } else if (dataField != null) {
              assistantMessage = dataField.toString();
            }

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

  @override
  void dispose() {
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
    final String viewportValue =
        (widget.selectedViewport == 'chat' ||
            widget.selectedViewport == 'diagnosis')
        ? widget.selectedViewport
        : 'chat';
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
                                      label: 'chat',
                                      selected: viewportValue == 'chat',
                                      isDarkMode: isDarkMode,
                                      gradient: animatedOutlineGradient,
                                      onTap: () =>
                                          widget.onViewportChanged('chat'),
                                    ),
                                  ),
                                  Expanded(
                                    child: _ViewportToggleButton(
                                      label: 'diagnosis',
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
                                            : MarkdownBody(
                                                data: message.text,
                                                selectable: true,
                                                onTapLink: (
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
                                                        TextDecoration.underline,
                                                  ),
                                                  h1: GoogleFonts.montserrat(
                                                    color: bodyTextColor,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  h2: GoogleFonts.montserrat(
                                                    color: bodyTextColor,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  h3: GoogleFonts.montserrat(
                                                    color: bodyTextColor,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  listBullet:
                                                      GoogleFonts.montserrat(
                                                        color: bodyTextColor,
                                                      ),
                                                  code: GoogleFonts.robotoMono(
                                                    color: bodyTextColor,
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
                                              ),
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
                                            Icons.pages_rounded,
                                            color:
                                                (_hasDiagnosis && !_isLoading)
                                                    ? controlIconColor
                                                    : disabledIconColor,
                                            size: 30,
                                          ),
                                          tooltip: _hasDiagnosis
                                              ? (_isLoading
                                                    ? 'Loading sources...'
                                                    : 'Get sources')
                                              : 'Run diagnosis first',
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
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}