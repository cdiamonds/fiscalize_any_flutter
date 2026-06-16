package com.fiscalize.fiscalize_any_droid.print

import android.util.Base64
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class FiscalizeApiClient(private val settings: SettingsStore) {

    private val http = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(120, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .build()

    fun fiscalizePdf(pdfBytes: ByteArray): FiscalizeResult {
        ensureToken()

        val multipart = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart(
                "file", "document.pdf",
                pdfBytes.toRequestBody("application/pdf".toMediaType())
            )
            .apply {
                settings.deviceId?.let { addFormDataPart("deviceId", it.toString()) }
            }
            .build()

        val request = Request.Builder()
            .url("${settings.apiUrl}/api/Invoices/FiscalizePdf")
            .post(multipart)
            .header("Authorization", "Bearer ${settings.authToken}")
            .build()

        val response = http.newCall(request).execute()

        if (response.code == 401) {
            // Token expired — refresh and retry once
            refreshToken()
            return fiscalizePdf(pdfBytes)
        }

        val body = response.body?.string()
            ?: throw IllegalStateException("Empty response from FiscalizePdf (HTTP ${response.code})")

        if (!response.isSuccessful) {
            throw IllegalStateException("FiscalizePdf failed (HTTP ${response.code}): $body")
        }

        return parseFiscalizeResult(body)
    }

    private fun ensureToken() {
        if (settings.authToken.isNullOrBlank()) {
            login()
        }
    }

    private fun login() {
        val json = JSONObject().apply {
            put("apiKey", settings.apiKey)
            put("apiSecret", settings.apiSecret)
        }.toString()

        val request = Request.Builder()
            .url("${settings.apiUrl}/api/DeviceAuths/Login")
            .post(json.toRequestBody("application/json".toMediaType()))
            .build()

        val response = http.newCall(request).execute()
        val body = response.body?.string()
            ?: throw IllegalStateException("Device login failed — empty response")

        if (!response.isSuccessful) {
            throw IllegalStateException("Device login failed (HTTP ${response.code}): $body")
        }

        val obj = JSONObject(body)
        settings.authToken = obj.getString("token")
        settings.refreshToken = obj.optString("refreshToken").takeIf { it.isNotBlank() }
        Log.d(TAG, "Device login successful")
    }

    private fun refreshToken() {
        val rt = settings.refreshToken
        if (rt.isNullOrBlank()) {
            login()
            return
        }

        val json = JSONObject().apply { put("refreshToken", rt) }.toString()
        val request = Request.Builder()
            .url("${settings.apiUrl}/api/DeviceAuths/RefreshToken")
            .post(json.toRequestBody("application/json".toMediaType()))
            .build()

        val response = http.newCall(request).execute()
        if (!response.isSuccessful) {
            // Refresh token expired — full login
            settings.authToken = null
            settings.refreshToken = null
            login()
            return
        }

        val obj = JSONObject(response.body!!.string())
        settings.authToken = obj.getString("token")
        settings.refreshToken = obj.optString("refreshToken").takeIf { it.isNotBlank() }
    }

    private fun parseFiscalizeResult(json: String): FiscalizeResult {
        val obj = JSONObject(json)
        val fiscal = obj.optJSONObject("invoiceFiscalData") ?: obj.optJSONObject("creditNoteFiscalData")

        val stampedPdfBase64 = obj.optString("stampedPdf", "")
        val stampedPdf = if (stampedPdfBase64.isNotBlank())
            Base64.decode(stampedPdfBase64, Base64.DEFAULT)
        else null

        val warnings = buildList {
            val arr = obj.optJSONArray("warnings") ?: return@buildList
            repeat(arr.length()) { add(arr.getString(it)) }
        }

        return FiscalizeResult(
            documentType = obj.optString("documentType", "Invoice"),
            stampedPdf = stampedPdf,
            suggestedFileName = obj.optString("suggestedFileName", "fiscal_document.pdf"),
            verificationCode = fiscal?.optString("verificationCode"),
            qrlUrl = fiscal?.optString("qrlUrl"),
            receiptNumber = fiscal?.optLong("receiptNumber") ?: 0L,
            globalNumber = fiscal?.optLong("globalNumber") ?: 0L,
            fiscalDayNumber = fiscal?.optInt("fiscalDayNumber") ?: 0,
            invoiceDate = fiscal?.optString("invoiceDate"),
            confidenceScore = obj.optInt("confidenceScore", 100),
            warnings = warnings,
            documentId = obj.optLong("documentId", 0L)
        )
    }

    companion object {
        private const val TAG = "FiscalizeApiClient"
    }
}
