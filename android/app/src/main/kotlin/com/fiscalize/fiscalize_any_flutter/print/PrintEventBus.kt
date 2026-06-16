package com.fiscalize.fiscalize_any_flutter.print

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

data class PrintEvent(
    val documentId: Long,
    val receiptNumber: String,
    val verificationCode: String?,
    val pdfPath: String?,
    val confidenceScore: Int,
    val warnings: List<String>
)

object PrintEventBus {
    private val _events = MutableSharedFlow<PrintEvent>(extraBufferCapacity = 16)
    val events = _events.asSharedFlow()

    fun post(event: PrintEvent) {
        _events.tryEmit(event)
    }
}
