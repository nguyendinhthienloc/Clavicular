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
        'https://physicians-optional-sweet-vegetation.trycloudflare.com';
    aiApiTunnel =
        dotenv.env['AI_API_TUNNEL'] ??
        'https://physicians-optional-sweet-vegetation.trycloudflare.com/api/ai/send-prompt';
  }

  static Future<void> initSingleton() => instance.init();

  static String get apiEndpoint => '${instance.backendTunnelUrl}/api';
  static String get backendTunnelUrlValue => instance.backendTunnelUrl;
  static String get aiApiTunnelValue => instance.aiApiTunnel;
}

final AppConfig appConfig = AppConfig.instance;
