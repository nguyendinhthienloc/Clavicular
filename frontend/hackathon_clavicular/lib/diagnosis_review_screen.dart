import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_config.dart';

class DiagnosisReviewScreen extends StatefulWidget {
  const DiagnosisReviewScreen({
    super.key,
    required this.isDarkMode,
    required this.bodyParts,
    required this.severity,
    required this.painType,
    required this.duration,
    required this.trigger,
    this.lat,
    this.lng,
  });

  final bool isDarkMode;
  final List<String> bodyParts;
  final String severity;
  final String painType;
  final String duration;
  final String trigger;
  final double? lat;
  final double? lng;

  @override
  State<DiagnosisReviewScreen> createState() => _DiagnosisReviewScreenState();
}

class _DiagnosisReviewScreenState extends State<DiagnosisReviewScreen>
    with SingleTickerProviderStateMixin {
  late final Dio _dio;
  AnimationController? _gradientController;

  bool _isLoading = true;
  String _reviewMarkdown = '';

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _fetchDiagnosisReview();
  }

  Future<void> _fetchDiagnosisReview() async {
    try {
      final Response<dynamic> response = await _dio
          .post<Map<String, dynamic>>(
            '${AppConfig.apiEndpoint}/ai/diagnose',
            data: <String, dynamic>{
              'bodyParts': widget.bodyParts,
              'severity': widget.severity,
              'painType': widget.painType,
              'duration': widget.duration,
              'trigger': widget.trigger,
              'lat': widget.lat,
              'lng': widget.lng,
            },
            options: Options(
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ),
          )
          .timeout(const Duration(seconds: 35));

      if (!mounted) return;

      String markdown = 'No diagnosis review returned.';
      final dynamic root = response.data;
      if (root is Map<String, dynamic>) {
        final dynamic payload = root['payload'];
        if (payload is Map<String, dynamic>) {
          final dynamic dataField = payload['data'];
          if (dataField is String && dataField.trim().isNotEmpty) {
            markdown = dataField;
          } else if (dataField != null) {
            markdown = dataField.toString();
          }
        } else if (payload is String && payload.trim().isNotEmpty) {
          markdown = payload;
        }
      }

      setState(() {
        _reviewMarkdown = markdown;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _reviewMarkdown = 'Failed to get diagnosis review.\n\n${error.message}';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _reviewMarkdown =
            'Unexpected error while loading diagnosis review.\n\n$error';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _gradientController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _gradientController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    final bool isDarkMode = widget.isDarkMode;
    final Color pageBackground = isDarkMode
        ? const Color(0xFF0A0E15)
        : const Color(0xFFE9EEF7);
    final Color viewportBackground = isDarkMode
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF4F6F8);
    final Color viewportBorder = isDarkMode
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFD4D9E0);
    final Color bubbleAssistant = isDarkMode
        ? const Color(0xFF262626)
        : const Color(0xFFFFFFFF);
    final Color bubbleBorder = isDarkMode
        ? const Color(0xFF3B3B3B)
        : const Color(0xFFD3D8E0);
    final Color bodyTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF1F2937);
    final List<Color> outlineColors = isDarkMode
        ? const [Color(0xFF60A5FA), Color(0xFF1D4ED8)]
        : const [Color(0xFF93C5FD), Color(0xFF2563EB)];

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        foregroundColor: bodyTextColor,
        title: Text(
          'Diagnosis Review',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
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
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: bodyTextColor),
                              const SizedBox(height: 12),
                              Text(
                                'Generating diagnosis review...',
                                style: GoogleFonts.montserrat(
                                  color: bodyTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: bubbleAssistant,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: bubbleBorder),
                              ),
                              child: MarkdownBody(
                                data: _reviewMarkdown,
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
                                  listBullet: GoogleFonts.montserrat(
                                    color: bodyTextColor,
                                  ),
                                  code: GoogleFonts.robotoMono(
                                    color: bodyTextColor,
                                    fontSize: 13,
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: isDarkMode
                                        ? const Color(0xFF1B1B1B)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
