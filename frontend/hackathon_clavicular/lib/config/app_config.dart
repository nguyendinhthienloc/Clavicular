import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static late final String backendTunnelUrl;
  static late final String aiApiTunnel;

  static Future<void> init() async {
    await dotenv.load();
    backendTunnelUrl =
        dotenv.env['BACKEND_TUNNEL_URL'] ?? 'http://localhost:3000';
    aiApiTunnel =
        dotenv.env['AI_API_TUNNEL'] ??
        'https://golf-divide-canyon-scanned.trycloudflare.com/api/ai/send-prompt';
  }

  static String get apiEndpoint => '$backendTunnelUrl/api';
}
