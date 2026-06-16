package com.fiscalize.fiscalize_any_droid

import android.os.Bundle
import com.fiscalize.fiscalize_any_droid.print.DocumentStore
import com.fiscalize.fiscalize_any_droid.print.PrintEventBus
import com.fiscalize.fiscalize_any_droid.print.SettingsStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {

    private lateinit var settings: SettingsStore
    private lateinit var documentStore: DocumentStore
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        settings = SettingsStore(applicationContext)
        documentStore = DocumentStore(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SETTINGS)
            .setMethodCallHandler { call, result ->
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_DOCUMENTS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listDocuments" -> result.success(documentStore.listDocuments())
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PRINT_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
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
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    companion object {
        private const val CHANNEL_SETTINGS = "com.fiscalize.anydroid/settings"
        private const val CHANNEL_DOCUMENTS = "com.fiscalize.anydroid/documents"
        private const val CHANNEL_PRINT_EVENTS = "com.fiscalize.anydroid/print_events"
    }
}
