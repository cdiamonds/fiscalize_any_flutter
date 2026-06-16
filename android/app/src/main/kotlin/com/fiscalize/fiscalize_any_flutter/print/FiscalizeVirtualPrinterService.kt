package com.fiscalize.fiscalize_any_flutter.print

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
import kotlinx.coroutines.cancel
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
        // Initialise PdfBox-Android font resources (required once per process)
        PdfTextExtractor.init(applicationContext)

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
                // ── Step 1: Read raw PDF bytes from the Android print job ──────────
                val pdfBytes = readPdfBytes(printJob.document)
                Log.d(TAG, "Read ${pdfBytes.size} bytes from print job")

                // ── Step 2: Extract text locally (mirrors FiscalyzeAny PdfService.ExtractText) ──
                val printText = PdfTextExtractor.extract(pdfBytes)
                Log.d(TAG, "Extracted ${printText.length} chars of text")

                // ── Step 3: Send text to server → fiscal data + print position returned ──
                // Endpoint: POST /api/Documents/Devices/PrintText  { printText: string }
                // Same endpoint FiscalyzeAny Windows calls in FolderMonitorService.
                val result = apiClient.sendPrintText(printText)
                Log.d(TAG, "Fiscalized: receipt #${result.receiptNumber}, confidence ${result.confidenceScore}%")

                // ── Step 4: Stamp PDF locally with QR + fiscal lines ──────────────
                // Mirrors FiscalyzeAny's PdfService.AddFiscalDataToPdf() using
                // PdfSharpCore + QRCoder. We use PdfBox-Android + ZXing instead.
                val stampedPdf = PdfStamper.stamp(pdfBytes, result)
                Log.d(TAG, "PDF stamped (${stampedPdf.size} bytes)")

                // ── Step 5: Persist for history and handle output ─────────────────
                val saved = documentStore.save(result, jobName, stampedPdf)

                val mode = settings.outputMode
                if (mode == SettingsStore.MODE_PRINT_ONLY || mode == SettingsStore.MODE_PRINT_AND_SAVE) {
                    printerClient.print(stampedPdf)
                }

                withContext(Dispatchers.Main) {
                    printJob.complete()
                    notifications.showSuccess(jobName, result)
                    PrintEventBus.post(
                        PrintEvent(
                            documentId = result.documentId,
                            receiptNumber = result.receiptNumber,
                            verificationCode = result.verificationCode,
                            pdfPath = saved?.pdfFile?.absolutePath,
                            confidenceScore = result.confidenceScore,
                            warnings = result.warnings
                        )
                    )
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

    override fun onRequestCancelPrintJob(printJob: PrintJob) {
        printJob.cancel()
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
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

            addPrinters(listOf(
                PrinterInfo.Builder(printerId, "Fiscalize Virtual Printer", PrinterInfo.STATUS_IDLE)
                    .setCapabilities(capabilities)
                    .build()
            ))
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
