package com.fiscalize.fiscalize_any_droid.print

data class FiscalizeResult(
    // Document identity
    val documentType: String,          // "Invoice" | "CreditNote" | "DebitNote"
    val docNo: String,
    val total: Double,
    val currency: String,

    // Fiscal data (from invoice.fiscalData or creditNote.fiscalData)
    val verificationCode: String,
    val qrlUrl: String,
    val receiptNumber: String,
    val globalNumber: String,
    val fiscalDayNumber: String,
    val receiptType: String,

    // Stamp placement settings (from printPosition — controls where QR goes on PDF)
    val stampPosition: Int,            // 0=BL, 1=BR, 2=TL, 3=TR, 4=BC
    val stampPage: Int,                // 0=last, 1=first
    val stampMarginPoints: Double,
    val stampMarginTopPoints: Double?,
    val stampMarginRightPoints: Double?,
    val stampMarginBottomPoints: Double?,
    val stampMarginLeftPoints: Double?,
    val stampQrSizePoints: Double,
    val paperSize: String,

    // Quality indicators
    val confidenceScore: Int,
    val warnings: List<String>,

    // Server-assigned document ID
    val documentId: Long
) {
    val hasWarnings get() = warnings.isNotEmpty()
    val isLowConfidence get() = confidenceScore < 60

    // QR code encodes the verification URL when available, falls back to the code itself
    val qrContent get() = if (qrlUrl.isNotEmpty()) qrlUrl else verificationCode
}
