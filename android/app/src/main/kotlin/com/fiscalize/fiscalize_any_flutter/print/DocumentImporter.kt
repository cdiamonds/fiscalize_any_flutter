package com.fiscalize.fiscalize_any_flutter.print

import android.content.Context
import android.util.Log
import java.io.File

class DocumentImporter(
    private val context: Context,
    private val settings: SettingsStore,
    private val apiClient: FiscalizeApiClient,
    private val documentStore: DocumentStore,
) {

    suspend fun import(
        filePath: String,
        fileName: String,
        onProgress: (step: String, label: String) -> Unit
    ): SavedDocument {
        onProgress("reading", "Reading document…")
        val pdfBytes = File(filePath).readBytes()
        if (pdfBytes.isEmpty()) throw IllegalStateException("Document is empty or unreadable")
        Log.d(TAG, "Read ${pdfBytes.size} bytes from $filePath")

        onProgress("extracting", "Extracting invoice text…")
        val printText = PdfTextExtractor.extract(pdfBytes)
        if (printText.isBlank()) throw IllegalStateException("No readable text found in document")
        Log.d(TAG, "Extracted ${printText.length} chars")

        onProgress("fiscalizing", "Fiscalizing with ZIMRA…")
        val result = apiClient.sendPrintText(printText)
        Log.d(TAG, "Fiscalized: receipt #${result.receiptNumber}")

        onProgress("stamping", "Stamping fiscal data onto PDF…")
        val stampedPdf = PdfStamper.stamp(pdfBytes, result)
        Log.d(TAG, "Stamped (${stampedPdf.size} bytes)")

        onProgress("saving", "Saving document…")
        val jobName = fileName.removeSuffix(".pdf").replace("_", " ").replace("-", " ")
        val saved = documentStore.save(result, jobName, stampedPdf)
            ?: throw IllegalStateException("Failed to save document")

        PrintEventBus.post(
            PrintEvent(
                documentId = result.documentId,
                receiptNumber = result.receiptNumber,
                verificationCode = result.verificationCode,
                pdfPath = saved.pdfFile.absolutePath,
                confidenceScore = result.confidenceScore,
                warnings = result.warnings
            )
        )

        return saved
    }

    companion object {
        private const val TAG = "DocumentImporter"
    }
}
