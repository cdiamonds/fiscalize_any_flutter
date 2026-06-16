package com.fiscalize.fiscalize_any_flutter.print

import android.content.Context
import android.os.Environment
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class DocumentStore(private val context: Context) {

    private val docsDir: File
        get() = File(context.getExternalFilesDir(null), "FiscalizeAny").also { it.mkdirs() }

    fun save(result: FiscalizeResult, jobName: String, stampedPdf: ByteArray): SavedDocument? {
        return try {
            val ts = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val baseName = sanitize("${result.documentType}_${result.docNo}".ifBlank { jobName })
            val pdfFile = File(docsDir, "${baseName}_$ts.pdf")
            val metaFile = File(docsDir, "${baseName}_$ts.json")

            pdfFile.writeBytes(stampedPdf)

            val meta = JSONObject().apply {
                put("jobName", jobName)
                put("pdfPath", pdfFile.absolutePath)
                put("documentType", result.documentType)
                put("docNo", result.docNo)
                put("total", result.total)
                put("currency", result.currency)
                put("verificationCode", result.verificationCode)
                put("qrlUrl", result.qrlUrl)
                put("receiptNumber", result.receiptNumber)
                put("globalNumber", result.globalNumber)
                put("fiscalDayNumber", result.fiscalDayNumber)
                put("confidenceScore", result.confidenceScore)
                put("documentId", result.documentId)
                put("savedAt", ts)
                put("warnings", JSONArray(result.warnings))
            }
            metaFile.writeText(meta.toString())

            Log.d(TAG, "Saved document to ${pdfFile.absolutePath}")
            SavedDocument(pdfFile, metaFile, result)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save document", e)
            null
        }
    }

    fun listDocuments(): List<Map<String, Any?>> {
        return docsDir.listFiles { f -> f.extension == "json" }
            ?.sortedByDescending { it.lastModified() }
            ?.mapNotNull { f ->
                try {
                    val obj = JSONObject(f.readText())
                    mapOf(
                        "jobName" to obj.optString("jobName"),
                        "pdfPath" to obj.optString("pdfPath"),
                        "documentType" to obj.optString("documentType"),
                        "docNo" to obj.optString("docNo"),
                        "total" to obj.optDouble("total"),
                        "currency" to obj.optString("currency"),
                        "verificationCode" to obj.optString("verificationCode"),
                        "qrlUrl" to obj.optString("qrlUrl"),
                        "receiptNumber" to obj.optString("receiptNumber"),
                        "fiscalDayNumber" to obj.optString("fiscalDayNumber"),
                        "confidenceScore" to obj.optInt("confidenceScore"),
                        "savedAt" to obj.optString("savedAt"),
                        "warnings" to (0 until (obj.optJSONArray("warnings")?.length() ?: 0))
                            .map { obj.optJSONArray("warnings")!!.getString(it) }
                    )
                } catch (e: Exception) {
                    null
                }
            } ?: emptyList()
    }

    private fun sanitize(name: String) =
        name.replace(Regex("[^a-zA-Z0-9_\\-]"), "_").take(60)

    companion object {
        private const val TAG = "DocumentStore"
    }
}

data class SavedDocument(
    val pdfFile: File,
    val metaFile: File,
    val result: FiscalizeResult
)
