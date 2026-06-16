import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/fiscal_document.dart';
import '../../core/services/document_service.dart';
import '../../core/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final void Function(FiscalDocument) onOpen;
  final VoidCallback onSettingsTap;
  const HistoryScreen({super.key, required this.onOpen, required this.onSettingsTap});

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
    _service.printEvents.listen((_) => _load());
  }

  Future<void> _load() async {
    final docs = await _service.listDocuments();
    if (mounted) setState(() { _docs = docs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surf,
        title: Text('Fiscal Documents', style: AppTextStyles.subheading(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textS),
            tooltip: 'Settings',
            onPressed: widget.onSettingsTap,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : _docs.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      Spacing.lg, Spacing.lg, Spacing.lg,
                      Spacing.lg + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: _docs.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.md),
                      child: _DocumentCard(doc: _docs[i], onTap: () => widget.onOpen(_docs[i])),
                    ),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: context.primaryBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: Spacing.xxl),
            Text('No fiscal documents yet', style: AppTextStyles.heading(context)),
            const SizedBox(height: Spacing.sm),
            Text(
              'Print an invoice from any Android app\nand select "Fiscalize Fiscal Printer"',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context),
            ),
            const SizedBox(height: Spacing.xxl),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: context.primaryBg,
                borderRadius: BorderRadius.circular(Radii.xxl),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Android Settings → Printing → Enable printer',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final FiscalDocument doc;
  final VoidCallback onTap;
  const _DocumentCard({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCreditNote = doc.documentType == 'CreditNote';
    final hasWarn = doc.hasWarnings;
    final isLow = doc.isLowConfidence && !hasWarn;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: hasWarn ? AppColors.error.withValues(alpha: 0.3)
                : isLow ? AppColors.warning.withValues(alpha: 0.3)
                : context.borderColor,
          ),
          boxShadow: AppShadows.card(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              // Icon chip
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isCreditNote
                      ? AppColors.warning.withValues(alpha: context.isDark ? 0.15 : 0.1)
                      : context.primaryBg,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(
                  isCreditNote ? Icons.undo_rounded : Icons.receipt_rounded,
                  color: isCreditNote ? AppColors.warning : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: Spacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.jobName,
                      style: AppTextStyles.bodyMedium(context),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(doc.subtitle, style: AppTextStyles.label(context)),
                    const SizedBox(height: 2),
                    Text(doc.formattedDate, style: AppTextStyles.caption(context)),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // Status badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasWarn)
                    _Badge(
                      label: '${doc.warnings.length}W',
                      bg: context.errorBg,
                      fg: context.isDark ? AppColors.errorDark : AppColors.error,
                    )
                  else if (isLow)
                    _Badge(
                      label: '${doc.confidenceScore}%',
                      bg: context.warningBg,
                      fg: context.isDark ? AppColors.warningDark : AppColors.warning,
                    )
                  else
                    _Badge(
                      label: '✓',
                      bg: context.successBg,
                      fg: context.isDark ? AppColors.successDark : AppColors.success,
                    ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right_rounded, size: 18, color: context.textM),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(Radii.xxl),
    ),
    child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
  );
}
