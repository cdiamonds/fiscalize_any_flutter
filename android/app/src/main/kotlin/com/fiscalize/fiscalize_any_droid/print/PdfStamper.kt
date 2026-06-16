package com.fiscalize.fiscalize_any_droid.print

import android.graphics.Bitmap
import android.util.Log
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPage
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font
import com.tom_roush.pdfbox.pdmodel.graphics.image.LosslessFactory
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

object PdfStamper {

    // StampPosition constants (same values as FiscalyzeAny)
    private const val POS_BOTTOM_LEFT  = 0
    private const val POS_BOTTOM_RIGHT = 1
    private const val POS_TOP_LEFT     = 2
    private const val POS_TOP_RIGHT    = 3
    private const val POS_BOTTOM_CENTER = 4

    /**
     * Stamps QR code + fiscal reference lines onto the PDF.
     * Mirrors FiscalyzeAny's PdfService.AddFiscalDataToPdf() / PdfSharpCore implementation.
     *
     * Returns the stamped PDF as a ByteArray.
     */
    fun stamp(originalPdf: ByteArray, result: FiscalizeResult): ByteArray {
        return try {
            PDDocument.load(ByteArrayInputStream(originalPdf)).use { doc ->
                val pageIndex = if (result.stampPage == 1) 0 else doc.numberOfPages - 1
                val page = doc.getPage(pageIndex)

                val qrBitmap = generateQrBitmap(result.qrContent, result.stampQrSizePoints.toInt())
                val pdImage = LosslessFactory.createFromImage(doc, qrBitmap)

                val (x, y) = computeStampOrigin(page, result, qrBitmap.width, qrBitmap.height)
                val qrPts = result.stampQrSizePoints.toFloat()

                PDPageContentStream(doc, page, PDPageContentStream.AppendMode.APPEND, true, true).use { cs ->
                    // Draw QR code
                    cs.drawImage(pdImage, x, y, qrPts, qrPts)

                    // Draw fiscal reference text below (or above) the QR
                    cs.setFont(PDType1Font.HELVETICA, 6f)
                    val lines = buildFiscalLines(result)
                    val lineHeight = 7f
                    val textX = x
                    var textY = y - lineHeight * lines.size - 2f

                    // If stamp is at top, put text below QR; if at bottom, put text above QR
                    if (result.stampPosition == POS_TOP_LEFT || result.stampPosition == POS_TOP_RIGHT) {
                        textY = y - lineHeight * lines.size - 2f
                    } else {
                        textY = y + qrPts + 2f
                    }

                    cs.beginText()
                    cs.newLineAtOffset(textX, textY)
                    for (line in lines) {
                        cs.showText(line)
                        cs.newLineAtOffset(0f, lineHeight)
                    }
                    cs.endText()
                }

                ByteArrayOutputStream().also { doc.save(it) }.toByteArray()
            }
        } catch (e: Exception) {
            Log.e(TAG, "PDF stamp failed — returning original", e)
            originalPdf // Return original if stamping fails; fiscalization already succeeded
        }
    }

    private fun computeStampOrigin(
        page: PDPage,
        result: FiscalizeResult,
        qrPx: Int,
        qrPy: Int
    ): Pair<Float, Float> {
        val box: PDRectangle = page.mediaBox
        val qrPts = result.stampQrSizePoints.toFloat()

        // Resolve per-side margins, falling back to uniform margin
        val m = result.stampMarginPoints.toFloat()
        val marginBottom = result.stampMarginBottomPoints?.toFloat() ?: m
        val marginTop    = result.stampMarginTopPoints?.toFloat()    ?: m
        val marginLeft   = result.stampMarginLeftPoints?.toFloat()   ?: m
        val marginRight  = result.stampMarginRightPoints?.toFloat()  ?: m

        val x = when (result.stampPosition) {
            POS_BOTTOM_RIGHT, POS_TOP_RIGHT -> box.width - qrPts - marginRight
            POS_BOTTOM_CENTER               -> (box.width - qrPts) / 2f
            else                            -> marginLeft   // BL / TL
        }

        val y = when (result.stampPosition) {
            POS_TOP_LEFT, POS_TOP_RIGHT     -> box.height - qrPts - marginTop
            else                            -> marginBottom  // BL / BR / BC
        }

        return x to y
    }

    private fun generateQrBitmap(content: String, sizePts: Int): Bitmap {
        // sizePts is in PDF points; generate at 2× for crisp rendering
        val sizePx = (sizePts * 2).coerceAtLeast(150)
        val hints = mapOf(EncodeHintType.MARGIN to 1)
        val matrix = QRCodeWriter().encode(content, BarcodeFormat.QR_CODE, sizePx, sizePx, hints)

        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.RGB_565)
        for (px in 0 until sizePx) {
            for (py in 0 until sizePx) {
                bmp.setPixel(px, py, if (matrix[px, py]) android.graphics.Color.BLACK else android.graphics.Color.WHITE)
            }
        }
        return bmp
    }

    private fun buildFiscalLines(result: FiscalizeResult): List<String> = buildList {
        if (result.verificationCode.isNotEmpty()) add("Code: ${result.verificationCode}")
        if (result.receiptNumber.isNotEmpty())    add("Receipt: ${result.receiptNumber}")
        if (result.fiscalDayNumber.isNotEmpty())  add("Day: ${result.fiscalDayNumber}")
        if (result.docNo.isNotEmpty())            add("Doc: ${result.docNo}")
    }

    private const val TAG = "PdfStamper"
}
