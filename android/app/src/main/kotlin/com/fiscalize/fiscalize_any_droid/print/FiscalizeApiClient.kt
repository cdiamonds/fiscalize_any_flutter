package com.fiscalize.fiscalize_any_droid.print

import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
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

    /**
     * Sends the extracted print text to POST /api/Documents/Devices/PrintText.
     * This mirrors exactly what FiscalyzeAny Windows does in FolderMonitorService.
     * The server extracts the invoice fields, fiscalizes with ZIMRA, and returns
     * the fiscal data + print position for local PDF stamping.
     */
    fun sendPrintText(printText: String): FiscalizeResult {
        ensureToken()

        val body = JSONObject().apply { put("printText", printText) }.toString()
        val request = Request.Builder()
            .url("${settings.apiUrl}/api/Documents/Devices/PrintText")
            .post(body.toRequestBody("application/json".toMediaType()))
            .header("Authorization", "Bearer ${settings.authToken}")
            .build()

        val response = http.newCall(request).execute()

        if (response.code == 401) {
            refreshToken()
            return sendPrintText(printText)
        }

        val responseBody = response.body?.string()
            ?: throw IllegalStateException("Empty response from PrintText (HTTP ${response.code})")

        if (!response.isSuccessful) {
            throw IllegalStateException("PrintText failed (HTTP ${response.code}): $responseBody")
        }

        Log.d(TAG, "PrintText response received (${responseBody.length} chars)")
        return parsePrintTextResponse(responseBody)
    }

    private fun ensureToken() {
        if (settings.authToken.isNullOrBlank()) login()
    }

    private fun login() {
        val body = JSONObject().apply {
            put("apiKey", settings.apiKey)
            put("apiSecret", settings.apiSecret)
        }.toString()

        val request = Request.Builder()
            .url("${settings.apiUrl}/api/DeviceAuths/Login")
            .post(body.toRequestBody("application/json".toMediaType()))
            .build()

        val response = http.newCall(request).execute()
        val responseBody = response.body?.string()
            ?: throw IllegalStateException("Device login failed — empty response")

        if (!response.isSuccessful) {
            throw IllegalStateException("Device login failed (HTTP ${response.code}): $responseBody")
        }

        val obj = JSONObject(responseBody)
        settings.authToken = obj.getString("token")
        settings.refreshToken = obj.optString("refreshToken").takeIf { it.isNotBlank() }
        Log.d(TAG, "Device login successful")
    }

    private fun refreshToken() {
        val rt = settings.refreshToken
        if (rt.isNullOrBlank()) { login(); return }

        val body = JSONObject().apply { put("refreshToken", rt) }.toString()
        val request = Request.Builder()
            .url("${settings.apiUrl}/api/auths/RefreshToken")
            .post(body.toRequestBody("application/json".toMediaType()))
            .build()

        val response = http.newCall(request).execute()
        if (!response.isSuccessful) {
            settings.authToken = null
            settings.refreshToken = null
            login()
            return
        }

        val obj = JSONObject(response.body!!.string())
        settings.authToken = obj.getString("token")
        settings.refreshToken = obj.optString("refreshToken").takeIf { it.isNotBlank() }
        Log.d(TAG, "Token refreshed")
    }

    private fun parsePrintTextResponse(json: String): FiscalizeResult {
        val root = JSONObject(json)

        val docType = root.optString("documentType", "Invoice")
        val doc = root.optJSONObject("invoice") ?: root.optJSONObject("creditNote")
        val fiscal = doc?.optJSONObject("fiscalData")
        val pos = root.optJSONObject("printPosition")

        val warnings = buildList {
            val arr = root.optJSONArray("warnings") ?: return@buildList
            repeat(arr.length()) { add(arr.getString(it)) }
        }

        return FiscalizeResult(
            documentType = docType,
            docNo = doc?.optString("docNo") ?: "",
            total = doc?.optDouble("total") ?: 0.0,
            currency = doc?.optString("currency") ?: "USD",

            verificationCode = fiscal?.optString("verificationCode") ?: "",
            qrlUrl = fiscal?.optString("qrlUrl") ?: "",
            receiptNumber = fiscal?.optString("receiptNumber") ?: "",
            globalNumber = fiscal?.optString("globalNumber") ?: "",
            fiscalDayNumber = fiscal?.optString("fiscalDayNumber") ?: "",
            receiptType = fiscal?.optString("receiptType") ?: "",

            stampPosition = pos?.optInt("stampPosition") ?: 1,
            stampPage = pos?.optInt("stampPage") ?: 0,
            stampMarginPoints = pos?.optDouble("stampMarginPoints") ?: 15.0,
            stampMarginTopPoints = pos?.takeIf { it.has("stampMarginTopPoints") }?.optDouble("stampMarginTopPoints"),
            stampMarginRightPoints = pos?.takeIf { it.has("stampMarginRightPoints") }?.optDouble("stampMarginRightPoints"),
            stampMarginBottomPoints = pos?.takeIf { it.has("stampMarginBottomPoints") }?.optDouble("stampMarginBottomPoints"),
            stampMarginLeftPoints = pos?.takeIf { it.has("stampMarginLeftPoints") }?.optDouble("stampMarginLeftPoints"),
            stampQrSizePoints = pos?.optDouble("stampQrSizePoints") ?: 75.0,
            paperSize = pos?.optString("paperSize") ?: "A4",

            confidenceScore = root.optDouble("confidenceScore", 100.0).toInt(),
            warnings = warnings,
            documentId = doc?.optLong("id") ?: 0L
        )
    }

    companion object {
        private const val TAG = "FiscalizeApiClient"
    }
}
