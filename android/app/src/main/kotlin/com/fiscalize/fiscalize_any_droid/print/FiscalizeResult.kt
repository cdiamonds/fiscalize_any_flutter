package com.fiscalize.fiscalize_any_droid.print

data class FiscalizeResult(
    val documentType: String,
    val stampedPdf: ByteArray?,
    val suggestedFileName: String,
    val verificationCode: String?,
    val qrlUrl: String?,
    val receiptNumber: Long,
    val globalNumber: Long,
    val fiscalDayNumber: Int,
    val invoiceDate: String?,
    val confidenceScore: Int,
    val warnings: List<String>,
    val documentId: Long
) {
    val hasWarnings get() = warnings.isNotEmpty()
    val isLowConfidence get() = confidenceScore < 60
}
