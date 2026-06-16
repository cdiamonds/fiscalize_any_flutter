import 'package:flutter/material.dart';
import '../../core/models/fiscal_document.dart';
import '../../core/services/document_service.dart';

class HistoryScreen extends StatefulWidget {
  final void Function(FiscalDocument) onOpen;
  const HistoryScreen({super.key, required this.onOpen});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _service = DocumentService();
  List<FiscalDocument> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh when a new print job completes
    _service.printEvents.listen((_) => _load());
  }

  Future<void> _load() async {
    final docs = await _service.listDocuments();
    if (mounted) setState(() { _docs = docs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No fiscal documents yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Print a document from any app and select\n"Fiscalize Fiscal Printer"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _docs.length,
        itemBuilder: (context, i) => _DocumentTile(
          doc: _docs[i],
          onTap: () => widget.onOpen(_docs[i]),
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final FiscalDocument doc;
  final VoidCallback onTap;

  const _DocumentTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  doc.documentType == 'CreditNote' ? Icons.undo : Icons.receipt,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.jobName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      doc.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      doc.formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (doc.hasWarnings)
                    Chip(
                      label: Text('${doc.warnings.length} warning${doc.warnings.length > 1 ? "s" : ""}'),
                      backgroundColor: cs.errorContainer,
                      labelStyle: TextStyle(color: cs.onErrorContainer, fontSize: 11),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (doc.isLowConfidence && !doc.hasWarnings)
                    Chip(
                      label: const Text('Low confidence'),
                      backgroundColor: cs.tertiaryContainer,
                      labelStyle: TextStyle(color: cs.onTertiaryContainer, fontSize: 11),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, color: cs.outlineVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
