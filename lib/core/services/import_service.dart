import 'package:flutter/services.dart';
import '../models/import_progress.dart';

const _channel  = MethodChannel('com.fiscalize.anymobile/import');
const _progress = EventChannel('com.fiscalize.anymobile/import_progress');

class ImportService {
  Future<void> importPdf({required String filePath, required String fileName}) async {
    await _channel.invokeMethod('importPdf', {
      'filePath': filePath,
      'fileName': fileName,
    });
  }

  Stream<ImportProgress> get progressStream =>
      _progress.receiveBroadcastStream().cast<Map<Object?, Object?>>().map(ImportProgress.fromMap);
}
