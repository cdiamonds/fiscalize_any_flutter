package com.fiscalize.fiscalize_any_droid.print

import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PrintAttributes
import android.print.PrinterCapabilitiesInfo
import android.print.PrinterId
import android.print.PrinterInfo
import android.printservice.PrintDocument
import android.printservice.PrintJob
import android.printservice.PrintService
import android.printservice.PrinterDiscoverySession
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class FiscalizeVirtualPrinterService : PrintService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private lateinit var settings: SettingsStore
    private lateinit var apiClient: FiscalizeApiClient
    private lateinit var printerClient: RealPrinterClient
    private lateinit var documentStore: DocumentStore
    private lateinit var notifications: NotificationHelper

    override fun onCreate() {
        super.onCreate()
        settings = SettingsStore(applicationContext)
        apiClient = FiscalizeApiClient(settings)
        printerClient = RealPrinterClient(settings)
        documentStore = DocumentStore(applicationContext)
        notifications = NotificationHelper(applicationContext)
    }

    override fun onCreatePrinterDiscoverySession(): PrinterDiscoverySession {
        return FiscalizePrinterDiscoverySession()
    }

    override fun onPrintJobQueued(printJob: PrintJob) {
        val jobName = printJob.info.label ?: "Untitled document"
        Log.d(TAG, "Print job queued: $jobName")

        if (!settings.isConfigured) {
            printJob.fail("FiscalizeAny is not configured. Open the app and enter your API credentials.")
            notifications.showFailure(jobName, "App not configured")
            return
        }

        startForeground(NotificationHelper.FOREGROUND_ID, notifications.buildProgressNotification(jobName))
        printJob.start()

        scope.launch {
            try {
                val pdfBytes = readPdfBytes(printJob.document)
                Log.d(TAG, "Read ${pdfBytes.size} bytes from print job")

                val result = apiClient.fiscalizePdf(pdfBytes)
                Log.d(TAG, "Fiscalized: receipt #${result.receiptNumber}, confidence ${result.confidenceScore}%")

                val saved = documentStore.save(result, jobName)

                val mode = settings.outputMode
                if ((mode == SettingsStore.MODE_PRINT_ONLY || mode == SettingsStore.MODE_PRINT_AND_SAVE)
                    && result.stampedPdf != null
                ) {
                    printerClient.print(result.stampedPdf)
                }

                withContext(Dispatchers.Main) {
                    printJob.complete()
                    notifications.showSuccess(jobName, result)
                    broadcastJobComplete(result, saved?.pdfFile?.absolutePath)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Print job failed", e)
                withContext(Dispatchers.Main) {
                    printJob.fail(e.message ?: "Unknown error")
                    notifications.showFailure(jobName, e.message ?: "Unknown error")
                }
            } finally {
                stopForeground(STOP_FOREGROUND_REMOVE)
            }
        }
    }

    private fun readPdfBytes(document: PrintDocument): ByteArray {
        val pfd: ParcelFileDescriptor = document.data
            ?: throw IllegalStateException("PrintDocument has no data")
        return ParcelFileDescriptor.AutoCloseInputStream(pfd).use { it.readBytes() }
    }

    private fun broadcastJobComplete(result: FiscalizeResult, pdfPath: String?) {
        // Signal MainActivity / Flutter EventChannel that a new document is available
        PrintEventBus.post(
            PrintEvent(
                documentId = result.documentId,
                receiptNumber = result.receiptNumber,
                verificationCode = result.verificationCode,
                pdfPath = pdfPath,
                confidenceScore = result.confidenceScore,
                warnings = result.warnings
            )
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.coroutineContext[SupervisorJob]?.cancel()
    }

    private inner class FiscalizePrinterDiscoverySession : PrinterDiscoverySession() {

        override fun onStartPrinterDiscovery(priorityList: MutableList<PrinterId>) {
            val printerId = generatePrinterId(PRINTER_ID)
            val capabilities = PrinterCapabilitiesInfo.Builder(printerId)
                .addMediaSize(PrintAttributes.MediaSize.ISO_A4, true)
                .addMediaSize(PrintAttributes.MediaSize.ISO_A5, false)
                .addResolution(PrintAttributes.Resolution("default", "300dpi", 300, 300), true)
                .setColorModes(
                    PrintAttributes.COLOR_MODE_COLOR or PrintAttributes.COLOR_MODE_MONOCHROME,
                    PrintAttributes.COLOR_MODE_COLOR
                )
                .build()

            val printer = PrinterInfo.Builder(printerId, "Fiscalize Fiscal Printer", PrinterInfo.STATUS_IDLE)
                .setCapabilities(capabilities)
                .build()

            addPrinters(listOf(printer))
        }

        override fun onStopPrinterDiscovery() {}
        override fun onValidatePrinters(printerIds: MutableList<PrinterId>) {}
        override fun onStartPrinterStateTracking(printerId: PrinterId) {}
        override fun onStopPrinterStateTracking(printerId: PrinterId) {}
        override fun onDestroy() {}
    }

    companion object {
        private const val TAG = "FiscalizeVirtualPrinter"
        private const val PRINTER_ID = "fiscalize_fiscal_printer"
    }
}
