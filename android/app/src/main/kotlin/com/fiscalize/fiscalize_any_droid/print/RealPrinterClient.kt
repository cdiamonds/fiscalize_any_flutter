package com.fiscalize.fiscalize_any_droid.print

import android.util.Log
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Socket

class RealPrinterClient(private val settings: SettingsStore) {

    fun print(pdfBytes: ByteArray) {
        val ip = settings.printerIp
        val port = settings.printerPort

        if (ip.isBlank()) throw IOException("Printer IP not configured")

        Log.d(TAG, "Connecting to printer at $ip:$port (${pdfBytes.size} bytes)")

        Socket().use { socket ->
            socket.connect(InetSocketAddress(ip, port), CONNECT_TIMEOUT_MS)
            socket.soTimeout = WRITE_TIMEOUT_MS
            socket.getOutputStream().use { out ->
                out.write(pdfBytes)
                out.flush()
            }
        }

        Log.d(TAG, "Print job sent successfully")
    }

    companion object {
        private const val TAG = "RealPrinterClient"
        private const val CONNECT_TIMEOUT_MS = 10_000
        private const val WRITE_TIMEOUT_MS = 30_000
    }
}
