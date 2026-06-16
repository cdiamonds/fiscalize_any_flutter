import 'package:flutter/services.dart';

const _channel = MethodChannel('com.fiscalize.anymobile/settings');

class AppSettings {
  String apiUrl;
  String apiKey;
  String apiSecret;
  String printerIp;
  int printerPort;
  String outputMode;
  int? deviceId;

  AppSettings({
    this.apiUrl = '',
    this.apiKey = '',
    this.apiSecret = '',
    this.printerIp = '',
    this.printerPort = 9100,
    this.outputMode = 'print_and_save',
    this.deviceId,
  });

  factory AppSettings.fromMap(Map<Object?, Object?> map) => AppSettings(
        apiUrl: (map['apiUrl'] as String?) ?? '',
        apiKey: (map['apiKey'] as String?) ?? '',
        apiSecret: (map['apiSecret'] as String?) ?? '',
        printerIp: (map['printerIp'] as String?) ?? '',
        printerPort: (map['printerPort'] as int?) ?? 9100,
        outputMode: (map['outputMode'] as String?) ?? 'print_and_save',
        deviceId: map['deviceId'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'apiUrl': apiUrl,
        'apiKey': apiKey,
        'apiSecret': apiSecret,
        'printerIp': printerIp,
        'printerPort': printerPort,
        'outputMode': outputMode,
        'deviceId': deviceId,
      };

  bool get isConfigured =>
      apiUrl.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;
}

class SettingsService {
  Future<AppSettings> load() async {
    final result = await _channel.invokeMethod<Map>('getSettings');
    if (result == null) return AppSettings();
    return AppSettings.fromMap(result as Map<Object?, Object?>);
  }

  Future<void> save(AppSettings settings) async {
    await _channel.invokeMethod('saveSettings', settings.toMap());
  }
}
