import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/models/fiscal_document.dart';

class DocumentDetailScreen extends StatefulWidget {
  final FiscalDocument doc;
  const DocumentDetailScreen({super.key, required this.doc});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _showPdf = false;

  FiscalDocument get doc => widget.doc;

  Future<void> _share() async {
    final file = XFile(doc.pdfPath, mimeType: 'application/pdf');
    await Share.shareXFiles([file], subject: doc.jobName);
  }

  Future<void> _openExternal() async {
    await OpenFilex.open(doc.pdfPath);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPdf = doc.pdfPath.isNotEmpty && File(doc.pdfPath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.jobName, overflow: TextOverflow.ellipsis),
        actions: [
          if (hasPdf) ...[
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open in PDF viewer',
              onPressed: _openExternal,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: _share,
            ),
          ],
        ],
      ),
      body: _showPdf && hasPdf
          ? Column(
              children: [
                _pdfBanner(cs),
                Expanded(child: SfPdfViewer.file(File(doc.pdfPath))),
              ],
            )
          : _detailView(cs, hasPdf),
      floatingActionButton: hasPdf
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showPdf = !_showPdf),
              icon: Icon(_showPdf ? Icons.info_outline : Icons.picture_as_pdf),
              label: Text(_showPdf ? 'Details' : 'View PDF'),
            )
          : null,
    );
  }

  Widget _pdfBanner(ColorScheme cs) => Container(
        color: cs.surfaceContainerHigh,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.verified, color: cs.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              'Stamped fiscal document',
              style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(onPressed: _share, child: const Text('Share')),
          ],
        ),
      );

  Widget _detailView(ColorScheme cs, bool hasPdf) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status banner
        _StatusBanner(doc: doc),
        const SizedBox(height: 16),

        // Fiscal data card
        _InfoCard(
          title: 'Fiscal Data',
          icon: Icons.receipt_long,
          children: [
            _InfoRow('Receipt Number', '#${doc.receiptNumber}'),
            _InfoRow('Fiscal Day', '${doc.fiscalDayNumber}'),
            _InfoRow('Invoice Date', doc.invoiceDate),
            _InfoRow('Document Type', doc.documentType),
            _InfoRow('Verification Code', doc.verificationCode, monospace: true),
          ],
        ),
        const SizedBox(height: 12),

        // QR Code
        if (doc.verificationCode.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code, color: cs.primary),
                      const SizedBox(width: 8),
                      Text('ZIMRA QR Code',
                          style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: QrImageView(
                      data: doc.qrlUrl.isNotEmpty ? doc.qrlUrl : doc.verificationCode,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doc.qrlUrl,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Warnings
        if (doc.hasWarnings)
          _InfoCard(
            title: 'Warnings',
            icon: Icons.warning_amber,
            iconColor: cs.error,
            children: doc.warnings.map((w) => _WarningRow(w)).toList(),
          ),
        const SizedBox(height: 12),

        // Actions
        if (hasPdf) ...[
          _InfoCard(
            title: 'Document',
            icon: Icons.picture_as_pdf,
            children: [
              _ActionRow(icon: Icons.share, label: 'Share PDF', onTap: _share),
              _ActionRow(icon: Icons.open_in_new, label: 'Open in PDF Viewer', onTap: _openExternal),
            ],
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final FiscalDocument doc;
  const _StatusBanner({required this.doc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOk = !doc.hasWarnings && !doc.isLowConfidence;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOk ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.warning,
            color: isOk ? cs.onPrimaryContainer : cs.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOk
                  ? 'Successfully fiscalized (${doc.confidenceScore}% confidence)'
                  : doc.hasWarnings
                      ? 'Fiscalized with ${doc.warnings.length} warning(s)'
                      : 'Low extraction confidence (${doc.confidenceScore}%)',
              style: TextStyle(
                color: isOk ? cs.onPrimaryContainer : cs.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? cs.primary, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: iconColor ?? cs.primary,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _InfoRow(this.label, this.value, {this.monospace = false});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ),
          Expanded(
            child: Text(
              value,
              style: monospace
                  ? const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)
                  : const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  final String warning;
  const _WarningRow(this.warning);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.circle, size: 6, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(warning, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(label),
              const Spacer(),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outlineVariant),
            ],
          ),
        ),
      );
}
