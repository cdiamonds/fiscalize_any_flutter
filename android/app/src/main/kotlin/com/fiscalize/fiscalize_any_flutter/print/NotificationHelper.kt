package com.fiscalize.fiscalize_any_flutter.print

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.fiscalize.fiscalize_any_flutter.MainActivity

class NotificationHelper(private val context: Context) {

    private val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_PROGRESS, "Fiscal Printing", NotificationManager.IMPORTANCE_LOW)
                .apply { description = "Active print job fiscalization progress" }
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_RESULT, "Fiscal Results", NotificationManager.IMPORTANCE_DEFAULT)
                .apply { description = "Completed and failed fiscal print jobs" }
        )
    }

    fun buildProgressNotification(jobName: String): Notification {
        return NotificationCompat.Builder(context, CHANNEL_PROGRESS)
            .setSmallIcon(android.R.drawable.ic_menu_send)
            .setContentTitle("Fiscalizing…")
            .setContentText(jobName)
            .setProgress(0, 0, true)
            .setOngoing(true)
            .build()
    }

    fun showSuccess(jobName: String, result: FiscalizeResult) {
        val intent = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("open_doc_id", result.documentId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val detail = buildString {
            result.verificationCode?.let { append("Receipt #${result.receiptNumber}") }
            if (result.hasWarnings) append(" ⚠ ${result.warnings.size} warning(s)")
        }

        val notif = NotificationCompat.Builder(context, CHANNEL_RESULT)
            .setSmallIcon(android.R.drawable.ic_menu_send)
            .setContentTitle("Fiscalized ✓  $jobName")
            .setContentText(detail.ifBlank { "Document fiscalized successfully" })
            .setContentIntent(intent)
            .setAutoCancel(true)
            .build()

        manager.notify(result.documentId.toInt(), notif)
    }

    fun showFailure(jobName: String, error: String) {
        val notif = NotificationCompat.Builder(context, CHANNEL_RESULT)
            .setSmallIcon(android.R.drawable.stat_notify_error)
            .setContentTitle("Fiscalization failed")
            .setContentText("$jobName — $error")
            .setAutoCancel(true)
            .build()

        manager.notify(System.currentTimeMillis().toInt(), notif)
    }

    fun cancel(id: Int) = manager.cancel(id)

    companion object {
        const val FOREGROUND_ID = 1001
        const val CHANNEL_PROGRESS = "fiscalize_progress"
        const val CHANNEL_RESULT = "fiscalize_result"
    }
}
