package com.fiscalize.fiscalize_any_flutter

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import com.fiscalize.fiscalize_any_flutter.print.DocumentImporter
import com.fiscalize.fiscalize_any_flutter.print.DocumentStore
import com.fiscalize.fiscalize_any_flutter.print.FiscalizeApiClient
import com.fiscalize.fiscalize_any_flutter.print.PdfTextExtractor
import com.fiscalize.fiscalize_any_flutter.print.PrintEventBus
import com.fiscalize.fiscalize_any_flutter.print.SettingsStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

class MainActivity : FlutterActivity() {

    private lateinit var settings: SettingsStore
    private lateinit var documentStore: DocumentStore
    private lateinit var importer: DocumentImporter
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // Import progress events — bridged to Flutter EventChannel
    private val _importProgress = MutableSharedFlow<Map<String, String?>>(extraBufferCapacity = 32)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        PdfTextExtractor.init(applicationContext)
        settings = SettingsStore(applicationContext)
        documentStore = DocumentStore(applicationContext)
        importer = DocumentImporter(applicationContext, settings, FiscalizeApiClient(settings), documentStore)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ── Settings ──────────────────────────────────────────────────
        MethodChannel(messenger, CHANNEL_SETTINGS).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSettings" -> result.success(settings.toMap())
                "saveSettings" -> {
                    @Suppress("UNCHECKED_CAST")
                    settings.applyFromMap(call.arguments as Map<String, Any?>)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // ── Documents ─────────────────────────────────────────────────
        MethodChannel(messenger, CHANNEL_DOCUMENTS).setMethodCallHandler { call, result ->
            when (call.method) {
                "listDocuments" -> result.success(documentStore.listDocuments())
                else -> result.notImplemented()
            }
        }

        // ── Import ────────────────────────────────────────────────────
        MethodChannel(messenger, CHANNEL_IMPORT).setMethodCallHandler { call, result ->
            when (call.method) {
                "importPdf" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as Map<String, Any?>
                    val filePath = args["filePath"] as? String
                    val fileName = args["fileName"] as? String ?: "document.pdf"
                    if (filePath == null) {
                        result.error("INVALID_ARG", "filePath is required", null)
                        return@setMethodCallHandler
                    }
                    if (!settings.isConfigured) {
                        result.error("NOT_CONFIGURED", "Configure API credentials in Settings first", null)
                        return@setMethodCallHandler
                    }
                    result.success(null) // acknowledge immediately; progress comes via EventChannel
                    scope.launch(Dispatchers.IO) {
                        try {
                            importer.import(filePath, fileName) { step, label ->
                                scope.launch { _importProgress.emit(mapOf("step" to step, "label" to label)) }
                            }
                            scope.launch { _importProgress.emit(mapOf("step" to "done", "label" to "Fiscalization complete")) }
                        } catch (e: Exception) {
                            Log.e(TAG, "Import failed", e)
                            scope.launch { _importProgress.emit(mapOf("step" to "error", "label" to (e.message ?: "Import failed"), "error" to e.message)) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // ── Print events ──────────────────────────────────────────────
        EventChannel(messenger, CHANNEL_PRINT_EVENTS).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                scope.launch {
                    PrintEventBus.events.collect { event ->
                        events.success(mapOf(
                            "documentId" to event.documentId,
                            "receiptNumber" to event.receiptNumber,
                            "verificationCode" to event.verificationCode,
                            "pdfPath" to event.pdfPath,
                            "confidenceScore" to event.confidenceScore,
                            "warnings" to event.warnings
                        ))
                    }
                }
            }
            override fun onCancel(arguments: Any?) {}
        })

        // ── Import progress events ────────────────────────────────────
        EventChannel(messenger, CHANNEL_IMPORT_PROGRESS).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                scope.launch {
                    _importProgress.asSharedFlow().collect { progress ->
                        events.success(progress)
                    }
                }
            }
            override fun onCancel(arguments: Any?) {}
        })
    }

    // Handle "Open with Fiscalize Any" intent for PDF files
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handlePdfIntent(intent)
    }

    private fun handlePdfIntent(intent: Intent) {
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> null
        }
        uri ?: return
        if (intent.type != "application/pdf" && uri.toString().endsWith(".pdf").not()) return

        val (path, name) = copyUriToCache(uri) ?: return
        if (!settings.isConfigured) return

        scope.launch(Dispatchers.IO) {
            try {
                importer.import(path, name) { step, label ->
                    scope.launch { _importProgress.emit(mapOf("step" to step, "label" to label)) }
                }
                scope.launch { _importProgress.emit(mapOf("step" to "done", "label" to "Fiscalization complete")) }
            } catch (e: Exception) {
                Log.e(TAG, "Intent import failed", e)
                scope.launch { _importProgress.emit(mapOf("step" to "error", "label" to (e.message ?: "Import failed"), "error" to e.message)) }
            }
        }
    }

    private fun copyUriToCache(uri: Uri): Pair<String, String>? {
        return try {
            val name = contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                cursor.moveToFirst()
                if (idx >= 0) cursor.getString(idx) else "document.pdf"
            } ?: "document.pdf"

            val cacheFile = java.io.File(cacheDir, "import_${System.currentTimeMillis()}_$name")
            contentResolver.openInputStream(uri)?.use { input ->
                cacheFile.outputStream().use { output -> input.copyTo(output) }
            }
            Pair(cacheFile.absolutePath, name)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to copy URI to cache", e)
            null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL_SETTINGS        = "com.fiscalize.anymobile/settings"
        private const val CHANNEL_DOCUMENTS       = "com.fiscalize.anymobile/documents"
        private const val CHANNEL_PRINT_EVENTS    = "com.fiscalize.anymobile/print_events"
        private const val CHANNEL_IMPORT          = "com.fiscalize.anymobile/import"
        private const val CHANNEL_IMPORT_PROGRESS = "com.fiscalize.anymobile/import_progress"
    }
}
