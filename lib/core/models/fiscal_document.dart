class FiscalDocument {
  final String jobName;
  final String pdfPath;
  final String documentType;
  final String docNo;
  final double total;
  final String currency;
  final String verificationCode;
  final String qrlUrl;
  final String receiptNumber;
  final String fiscalDayNumber;
  final int confidenceScore;
  final String savedAt;
  final List<String> warnings;

  const FiscalDocument({
    required this.jobName,
    required this.pdfPath,
    required this.documentType,
    required this.docNo,
    required this.total,
    required this.currency,
    required this.verificationCode,
    required this.qrlUrl,
    required this.receiptNumber,
    required this.fiscalDayNumber,
    required this.confidenceScore,
    required this.savedAt,
    required this.warnings,
  });

  factory FiscalDocument.fromMap(Map<Object?, Object?> map) {
    return FiscalDocument(
      jobName: (map['jobName'] as String?) ?? '',
      pdfPath: (map['pdfPath'] as String?) ?? '',
      documentType: (map['documentType'] as String?) ?? 'Invoice',
      docNo: (map['docNo'] as String?) ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] as String?) ?? 'USD',
      verificationCode: (map['verificationCode'] as String?) ?? '',
      qrlUrl: (map['qrlUrl'] as String?) ?? '',
      receiptNumber: (map['receiptNumber'] as String?) ?? '',
      fiscalDayNumber: (map['fiscalDayNumber'] as String?) ?? '',
      confidenceScore: (map['confidenceScore'] as int?) ?? 100,
      savedAt: (map['savedAt'] as String?) ?? '',
      warnings: ((map['warnings'] as List?)?.cast<String>()) ?? [],
    );
  }

  bool get hasWarnings => warnings.isNotEmpty;
  bool get isLowConfidence => confidenceScore < 60;

  String get formattedDate {
    if (savedAt.length < 15) return savedAt;
    // yyyyMMdd_HHmmss → DD/MM/YYYY HH:MM
    return '${savedAt.substring(6, 8)}/${savedAt.substring(4, 6)}/${savedAt.substring(0, 4)}'
        ' ${savedAt.substring(9, 11)}:${savedAt.substring(11, 13)}';
  }

  String get subtitle => docNo.isNotEmpty
      ? '$docNo  •  $currency ${total.toStringAsFixed(2)}'
      : 'Receipt #$receiptNumber';
}
