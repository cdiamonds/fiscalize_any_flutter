import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/models/fiscal_document.dart';
import '../../core/theme/app_theme.dart';

class DocumentDetailScreen extends StatefulWidget {
  final FiscalDocument doc;
  const DocumentDetailScreen({super.key, required this.doc});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> with SingleTickerProviderStateMixin {
  bool _showPdf = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  FiscalDocument get doc => widget.doc;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: AppDurations.reveal);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: AppCurves.decelerate);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final file = XFile(doc.pdfPath, mimeType: 'application/pdf');
    await Share.shareXFiles([file], subject: doc.jobName);
  }

  Future<void> _openExternal() async => OpenFilex.open(doc.pdfPath);

  Future<void> _copyVerificationCode() async {
    await Clipboard.setData(ClipboardData(text: doc.verificationCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPdf = doc.pdfPath.isNotEmpty && File(doc.pdfPath).existsSync();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surf,
        title: Text(doc.jobName, style: AppTextStyles.subheading(context), overflow: TextOverflow.ellipsis),
        actions: [
          if (hasPdf) ...[
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Open externally',
              onPressed: _openExternal,
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share',
              onPressed: _share,
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: _showPdf && hasPdf
          ? Column(
              children: [
                _PdfBanner(onShare: _share),
                Expanded(child: SfPdfViewer.file(File(doc.pdfPath))),
              ],
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: _DetailBody(
                doc: doc,
                hasPdf: hasPdf,
                onShare: _share,
                onOpenExternal: _openExternal,
                onCopyCode: _copyVerificationCode,
              ),
            ),
      floatingActionButton: hasPdf
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showPdf = !_showPdf),
              icon: Icon(_showPdf ? Icons.info_outline_rounded : Icons.picture_as_pdf_rounded),
              label: Text(_showPdf ? 'Details' : 'View PDF'),
            )
          : null,
    );
  }
}

class _PdfBanner extends StatelessWidget {
  final VoidCallback onShare;
  const _PdfBanner({required this.onShare});

  @override
  Widget build(BuildContext context) => Container(
    color: context.surf,
    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
    child: Row(
      children: [
        Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          'Fiscally stamped document',
          style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        TextButton(onPressed: onShare, child: const Text('Share')),
      ],
    ),
  );
}

class _DetailBody extends StatelessWidget {
  final FiscalDocument doc;
  final bool hasPdf;
  final VoidCallback onShare;
  final VoidCallback onOpenExternal;
  final VoidCallback onCopyCode;

  const _DetailBody({
    required this.doc, required this.hasPdf,
    required this.onShare, required this.onOpenExternal, required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    final isOk = !doc.hasWarnings && !doc.isLowConfidence;
    final isCreditNote = doc.documentType == 'CreditNote';

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Spacing.lg, Spacing.lg, Spacing.lg,
        Spacing.massive + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        // ── Status Banner ───────────────────────────────────────────
        AnimatedContainer(
          duration: AppDurations.normal, curve: AppCurves.spring,
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: isOk ? context.successBg : doc.hasWarnings ? context.errorBg : context.warningBg,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(
              color: isOk
                  ? AppColors.success.withValues(alpha: 0.3)
                  : doc.hasWarnings
                      ? AppColors.error.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOk ? Icons.verified_rounded
                    : doc.hasWarnings ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                color: isOk
                    ? (context.isDark ? AppColors.successDark : AppColors.success)
                    : doc.hasWarnings
                        ? (context.isDark ? AppColors.errorDark : AppColors.error)
                        : (context.isDark ? AppColors.warningDark : AppColors.warning),
                size: 22,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOk ? 'Successfully fiscalized'
                          : doc.hasWarnings ? '${doc.warnings.length} warning(s)'
                          : 'Low extraction confidence',
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    Text(
                      '${doc.confidenceScore}% confidence · ${isCreditNote ? 'Credit Note' : 'Invoice'}',
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // ── Fiscal Data ─────────────────────────────────────────────
        _InfoCard(
          title: 'Fiscal Data',
          icon: Icons.receipt_long_rounded,
          children: [
            if (doc.docNo.isNotEmpty) _InfoRow(label: 'Document No.', value: doc.docNo),
            _InfoRow(label: 'Type', value: doc.documentType),
            _InfoRow(label: 'Total', value: '${doc.currency} ${doc.total.toStringAsFixed(2)}'),
            _InfoRow(label: 'Receipt Number', value: doc.receiptNumber),
            _InfoRow(label: 'Fiscal Day', value: doc.fiscalDayNumber),
          ],
        ),
        const SizedBox(height: Spacing.md),

        // ── Verification Code ───────────────────────────────────────
        if (doc.verificationCode.isNotEmpty) ...[
          _InfoCard(
            title: 'Verification',
            icon: Icons.security_rounded,
            trailing: GestureDetector(
              onTap: onCopyCode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Copy', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                decoration: BoxDecoration(
                  color: context.surfDim,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(color: context.borderColor),
                ),
                child: Text(
                  doc.verificationCode,
                  style: AppTextStyles.mono(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
        ],

        // ── QR Code ─────────────────────────────────────────────────
        if (doc.verificationCode.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: context.borderColor),
              boxShadow: AppShadows.card(context),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('ZIMRA QR Code',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: QrImageView(
                      data: doc.qrlUrl.isNotEmpty ? doc.qrlUrl : doc.verificationCode,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0D9488),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                if (doc.qrlUrl.isNotEmpty) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    doc.qrlUrl,
                    style: AppTextStyles.caption(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],

        // ── Warnings ─────────────────────────────────────────────────
        if (doc.hasWarnings) ...[
          _InfoCard(
            title: 'Warnings',
            icon: Icons.warning_amber_rounded,
            iconColor: context.isDark ? AppColors.warningDark : AppColors.warning,
            children: doc.warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.isDark ? AppColors.warningDark : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(child: Text(w, style: AppTextStyles.body(context))),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: Spacing.md),
        ],

        // ── Document Actions ─────────────────────────────────────────
        if (hasPdf) ...[
          _InfoCard(
            title: 'Document',
            icon: Icons.picture_as_pdf_rounded,
            children: [
              _ActionTile(icon: Icons.share_rounded, label: 'Share PDF', onTap: onShare),
              _ActionTile(icon: Icons.open_in_new_rounded, label: 'Open in PDF Viewer', onTap: onOpenExternal, isLast: true),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Shared card + row widgets ───────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;
  final List<Widget> children;

  const _InfoCard({
    required this.title, required this.icon, required this.children,
    this.iconColor, this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Spacing.lg),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(Radii.lg),
      border: Border.all(color: context.borderColor),
      boxShadow: AppShadows.card(context),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor ?? AppColors.primary),
            const SizedBox(width: 6),
            Text(title, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: iconColor ?? AppColors.primary,
            )),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ),
        const SizedBox(height: Spacing.md),
        ...children,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.label(context)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium(context)),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(Radii.sm),
    child: Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : Spacing.sm),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(Radii.sm)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium(context))),
          Icon(Icons.chevron_right_rounded, size: 18, color: context.textM),
        ],
      ),
    ),
  );
}
