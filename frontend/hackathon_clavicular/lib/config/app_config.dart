import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();

  late final String backendTunnelUrl;
  late final String aiApiTunnel;
  bool isDarkMode = true;

  Future<void> init() async {
    await dotenv.load();
    backendTunnelUrl =
        dotenv.env['BACKEND_TUNNEL_URL'] ?? 'http://localhost:3000';
    aiApiTunnel =
        dotenv.env['AI_API_TUNNEL'] ??
        'https://golf-divide-canyon-scanned.trycloudflare.com/api/ai/send-prompt';
  }

  static Future<void> initSingleton() => instance.init();

  static String get apiEndpoint => '${instance.backendTunnelUrl}/api';
  static String get backendTunnelUrlValue => instance.backendTunnelUrl;
  static String get aiApiTunnelValue => instance.aiApiTunnel;
}

final AppConfig appConfig = AppConfig.instance;
