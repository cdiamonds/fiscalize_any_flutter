import 'package:flutter/services.dart';
import '../models/fiscal_document.dart';

const _channel = MethodChannel('com.fiscalize.anydroid/documents');
const _events = EventChannel('com.fiscalize.anydroid/print_events');

class DocumentService {
  Future<List<FiscalDocument>> listDocuments() async {
    final result = await _channel.invokeMethod<List>('listDocuments');
    if (result == null) return [];
    return result
        .cast<Map<Object?, Object?>>()
        .map(FiscalDocument.fromMap)
        .toList();
  }

  Stream<Map<Object?, Object?>> get printEvents =>
      _events.receiveBroadcastStream().cast<Map<Object?, Object?>>();
}
