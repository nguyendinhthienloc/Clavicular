import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'config/app_config.dart';

class ViewportChat extends StatefulWidget {
  const ViewportChat({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.selectedViewport,
    required this.onViewportChanged,
    this.injectedAssistantMessage,
    this.injectedAssistantVersion = 0,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String selectedViewport;
  final ValueChanged<String> onViewportChanged;
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

            // Extract from data field first
            final dynamic dataField = responseData['payload'];
            String assistantMessage = '';

            if (dataField is String) {
              assistantMessage = dataField;
            } else if (dataField is Map<String, dynamic>) {
              // If data is a map, try to find text in it
              assistantMessage = dataField['data'] ?? '';
            } else if (dataField != null) {
              assistantMessage = dataField.toString();
            }

            if (assistantMessage.isEmpty) {
              // If still empty, show what was actually received
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
    final Color footerTextColor = isDarkMode
        ? const Color(0xFFC8C8C8)
        : const Color(0xFF6B7280);
    final Color dropdownText = isDarkMode
        ? const Color(0xFFEAF1FF)
        : Colors.white;
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
            child: Container(
              margin: const EdgeInsets.all(1.4),
              decoration: BoxDecoration(
                color: viewportBackground,
                border: Border.all(color: viewportBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scaffold(
                backgroundColor: viewportBackground,
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: animatedOutlineGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: viewportValue,
                                iconEnabledColor: dropdownText,
                                dropdownColor: isDarkMode
                                    ? const Color(0xFF0E1B38)
                                    : const Color(0xFF2563EB),
                                style: GoogleFonts.montserrat(
                                  color: dropdownText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'chat',
                                    child: Text('chat'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'diagnosis',
                                    child: Text('diagnosis'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  widget.onViewportChanged(value);
                                },
                              ),
                            ),
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
                                if (_isLoading && index == _messages.length) {
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
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: bubbleBorder),
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
                                final _ChatMessage message = _messages[index];
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
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: bubbleBorder),
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
                                            styleSheet: MarkdownStyleSheet(
                                              p: GoogleFonts.montserrat(
                                                color: bodyTextColor,
                                                fontSize: 14,
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
                                  duration: const Duration(milliseconds: 250),
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
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: animatedOutlineGradient,
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(1.4),
                                decoration: BoxDecoration(
                                  color: composerBackground,
                                  borderRadius: BorderRadius.circular(24.6),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    20,
                                    12,
                                    20,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: controlIconColor,
                                        size: 30,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: _controller,
                                          maxLines: 1,
                                          textInputAction: TextInputAction.send,
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
                                        icon: Icon(
                                          Icons.send_rounded,
                                          color: controlIconColor,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  'Connect your tools to Assistant',
                                  style: GoogleFonts.montserrat(
                                    color: footerTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
