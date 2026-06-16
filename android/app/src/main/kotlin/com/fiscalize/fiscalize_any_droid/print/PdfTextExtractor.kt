package com.fiscalize.fiscalize_any_droid.print

import android.content.Context
import android.util.Log
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import java.io.ByteArrayInputStream

object PdfTextExtractor {

    private var initialized = false

    fun init(context: Context) {
        if (!initialized) {
            PDFBoxResourceLoader.init(context)
            initialized = true
        }
    }

    /**
     * Extracts text from PDF bytes. Mirrors FiscalyzeAny's PdfService.ExtractText()
     * which uses UglyToad.PdfPig to produce line-ordered text suitable for the
     * server's extraction rules and the PrintText endpoint.
     */
    fun extract(pdfBytes: ByteArray): String {
        return try {
            PDDocument.load(ByteArrayInputStream(pdfBytes)).use { doc ->
                val stripper = PDFTextStripper().apply {
                    sortByPosition = true      // position-ordered — matches PdfPig behaviour
                    addMoreFormatting = false
                }
                stripper.getText(doc)
            }
        } catch (e: Exception) {
            Log.e(TAG, "PDF text extraction failed", e)
            throw IllegalStateException("Could not extract text from PDF: ${e.message}", e)
        }
    }

    private const val TAG = "PdfTextExtractor"
}
