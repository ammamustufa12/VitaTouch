import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ndef_text.dart';

class NfcSnapshot {
  const NfcSnapshot({
    required this.ok,
    required this.present,
    this.readerName,
    this.uid,
    this.message,
    this.error,
  });

  final bool ok;
  final bool present;
  final String? readerName;
  final String? uid;
  final String? message;
  final String? error;

  bool get bridgeDown => !ok && present == false && readerName == null;

  factory NfcSnapshot.offline(String error) {
    return NfcSnapshot(ok: false, present: false, error: error);
  }

  factory NfcSnapshot.fromJson(Map<String, dynamic> json) {
    final pages = (json['pages'] as List<dynamic>? ?? const [])
        .map((page) => '$page')
        .toList();
    final uid = json['uid'] as String?;
    return NfcSnapshot(
      ok: json['ok'] as bool? ?? false,
      present: json['present'] as bool? ?? false,
      readerName: json['readerName'] as String?,
      uid: uid == null || uid.isEmpty ? null : formatNfcUid(uid),
      message: pages.isEmpty ? null : ndefTextFromPages(pages),
      error: json['error'] as String?,
    );
  }
}

class NfcBridgeClient {
  NfcBridgeClient({HttpClient? httpClient, String? url})
      : _httpClient = httpClient ?? HttpClient(),
        url = url ?? nfcBridgeUrl();

  final HttpClient _httpClient;
  final String url;

  Future<NfcSnapshot> read() async {
    try {
      final request = await _httpClient
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 2));
      final response = await request.close().timeout(const Duration(seconds: 3));
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        return NfcSnapshot.offline('The NFC bridge did not answer.');
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return NfcSnapshot.offline('The NFC bridge sent an unexpected reply.');
      }
      return NfcSnapshot.fromJson(decoded);
    } on TimeoutException {
      return NfcSnapshot.offline('The NFC reader did not answer in time.');
    } catch (_) {
      return NfcSnapshot.offline(
        'The NFC bridge on this computer is not running.',
      );
    }
  }

  void close() {
    _httpClient.close(force: true);
  }
}

String nfcBridgeUrl() {
  const host = String.fromEnvironment('NFC_HOST');
  if (host.isNotEmpty) {
    return 'http://$host:8765/nfc';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8765/nfc';
  }
  return 'http://127.0.0.1:8765/nfc';
}
