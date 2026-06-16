package com.fiscalize.fiscalize_any_flutter.print

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class SettingsStore(context: Context) {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        PREFS_FILE,
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    var apiUrl: String
        get() = prefs.getString(KEY_API_URL, "") ?: ""
        set(v) = prefs.edit().putString(KEY_API_URL, v).apply()

    var apiKey: String
        get() = prefs.getString(KEY_API_KEY, "") ?: ""
        set(v) = prefs.edit().putString(KEY_API_KEY, v).apply()

    var apiSecret: String
        get() = prefs.getString(KEY_API_SECRET, "") ?: ""
        set(v) = prefs.edit().putString(KEY_API_SECRET, v).apply()

    var deviceId: Long?
        get() = prefs.getLong(KEY_DEVICE_ID, -1L).takeIf { it != -1L }
        set(v) = if (v != null) prefs.edit().putLong(KEY_DEVICE_ID, v).apply()
                 else prefs.edit().remove(KEY_DEVICE_ID).apply()

    var printerIp: String
        get() = prefs.getString(KEY_PRINTER_IP, "") ?: ""
        set(v) = prefs.edit().putString(KEY_PRINTER_IP, v).apply()

    var printerPort: Int
        get() = prefs.getInt(KEY_PRINTER_PORT, 9100)
        set(v) = prefs.edit().putInt(KEY_PRINTER_PORT, v).apply()

    var outputMode: String
        get() = prefs.getString(KEY_OUTPUT_MODE, MODE_PRINT_AND_SAVE) ?: MODE_PRINT_AND_SAVE
        set(v) = prefs.edit().putString(KEY_OUTPUT_MODE, v).apply()

    var authToken: String?
        get() = prefs.getString(KEY_AUTH_TOKEN, null)
        set(v) = if (v != null) prefs.edit().putString(KEY_AUTH_TOKEN, v).apply()
                 else prefs.edit().remove(KEY_AUTH_TOKEN).apply()

    var refreshToken: String?
        get() = prefs.getString(KEY_REFRESH_TOKEN, null)
        set(v) = if (v != null) prefs.edit().putString(KEY_REFRESH_TOKEN, v).apply()
                 else prefs.edit().remove(KEY_REFRESH_TOKEN).apply()

    val isConfigured: Boolean
        get() = apiUrl.isNotBlank() && apiKey.isNotBlank() && apiSecret.isNotBlank()

    fun applyFromMap(map: Map<String, Any?>) {
        (map["apiUrl"] as? String)?.let { apiUrl = it }
        (map["apiKey"] as? String)?.let { apiKey = it }
        (map["apiSecret"] as? String)?.let { apiSecret = it }
        (map["printerIp"] as? String)?.let { printerIp = it }
        (map["printerPort"] as? Int)?.let { printerPort = it }
        (map["outputMode"] as? String)?.let { outputMode = it }
        (map["deviceId"] as? Long)?.let { deviceId = it }
        // Clear cached auth token when credentials change
        authToken = null
        refreshToken = null
    }

    fun toMap(): Map<String, Any?> = mapOf(
        "apiUrl" to apiUrl,
        "apiKey" to apiKey,
        "apiSecret" to apiSecret,
        "printerIp" to printerIp,
        "printerPort" to printerPort,
        "outputMode" to outputMode,
        "deviceId" to deviceId
    )

    companion object {
        const val PREFS_FILE = "fiscalize_any_settings"
        const val KEY_API_URL = "api_url"
        const val KEY_API_KEY = "api_key"
        const val KEY_API_SECRET = "api_secret"
        const val KEY_DEVICE_ID = "device_id"
        const val KEY_PRINTER_IP = "printer_ip"
        const val KEY_PRINTER_PORT = "printer_port"
        const val KEY_OUTPUT_MODE = "output_mode"
        const val KEY_AUTH_TOKEN = "auth_token"
        const val KEY_REFRESH_TOKEN = "refresh_token"

        const val MODE_PRINT_ONLY = "print"
        const val MODE_SAVE_ONLY = "save"
        const val MODE_PRINT_AND_SAVE = "print_and_save"
        const val MODE_ASK = "ask"
    }
}
