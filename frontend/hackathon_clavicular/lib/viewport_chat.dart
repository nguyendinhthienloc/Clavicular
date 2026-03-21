import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'config/app_config.dart';

class ViewportChat extends StatefulWidget {
  const ViewportChat({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<ViewportChat> createState() => _ViewportChatState();
}

class _ViewportChatState extends State<ViewportChat> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  late final Dio _dio;
  bool _isTyping = false;
  bool _hasSentFirstMessage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTypingState);
    _dio = Dio();
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

            // Debug: Log the actual response
            print('API Response: $responseData');

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final Color composerBorder = isDarkMode
        ? const Color(0xFF454545)
        : const Color(0xFFD1D5DB);
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: viewportBackground,
          border: Border.all(color: viewportBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Scaffold(
          backgroundColor: viewportBackground,
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (hasMessages)
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (BuildContext context, int index) {
                          if (_isLoading && index == _messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: const BoxConstraints(maxWidth: 420),
                              decoration: BoxDecoration(
                                color: message.isUser
                                    ? bubbleUser
                                    : bubbleAssistant,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: bubbleBorder),
                              ),
                              child: Text(
                                message.text,
                                style: GoogleFonts.montserrat(
                                  color: bodyTextColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    IgnorePointer(
                      child: Center(
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeInOut,
                          offset: Offset(
                            0.0,
                            _hasSentFirstMessage
                                ? -1.2
                                : _isTyping
                                ? -0.25
                                : 0.0,
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeInOut,
                            opacity: _hasSentFirstMessage ? 0 : 1,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Text(
                                'clavicular',
                                style: GoogleFonts.montserrat(
                                  color: heroTextColor,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
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
                          color: composerBackground,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: composerBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 12, 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                                    hintText: 'How can I help you today?',
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
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
