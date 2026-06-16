import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/import_progress.dart';
import '../../core/services/import_service.dart';
import '../../core/theme/app_theme.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> with TickerProviderStateMixin {
  final _service = ImportService();
  StreamSubscription<ImportProgress>? _progressSub;

  _ImportState _state = _ImportState.idle;
  ImportProgress? _currentProgress;
  String? _selectedFileName;
  String? _error;

  // Steps in display order
  static const _steps = [
    ImportStep.reading,
    ImportStep.extracting,
    ImportStep.fiscalizing,
    ImportStep.stamping,
    ImportStep.saving,
  ];

  @override
  void initState() {
    super.initState();
    _progressSub = _service.progressStream.listen(_onProgress);
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  void _onProgress(ImportProgress progress) {
    setState(() => _currentProgress = progress);
    if (progress.step == ImportStep.done) {
      setState(() => _state = _ImportState.done);
    } else if (progress.step == ImportStep.error) {
      setState(() {
        _state = _ImportState.error;
        _error = progress.error ?? progress.label;
      });
    } else {
      setState(() => _state = _ImportState.processing);
    }
  }

  Future<void> _pickAndImport() async {
    setState(() { _state = _ImportState.idle; _error = null; _currentProgress = null; _selectedFileName = null; });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() {
      _selectedFileName = file.name;
      _state = _ImportState.processing;
    });

    try {
      await _service.importPdf(filePath: file.path!, fileName: file.name);
    } catch (e) {
      setState(() {
        _state = _ImportState.error;
        _error = e.toString().replaceFirst('PlatformException(', '').split(',').first;
      });
    }
  }

  void _reset() => setState(() {
    _state = _ImportState.idle;
    _currentProgress = null;
    _selectedFileName = null;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surf,
        title: Text('Import Document', style: AppTextStyles.subheading(context)),
        actions: [
          if (_state != _ImportState.idle && _state != _ImportState.processing)
            TextButton(
              onPressed: _reset,
              child: Text('New Import', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: AppDurations.normal,
        switchInCurve: AppCurves.decelerate,
        switchOutCurve: AppCurves.decelerate,
        child: switch (_state) {
          _ImportState.idle       => _IdleView(onImport: _pickAndImport),
          _ImportState.processing => _ProcessingView(
              fileName: _selectedFileName,
              currentStep: _currentProgress?.step ?? ImportStep.reading,
              currentLabel: _currentProgress?.label ?? 'Starting…',
              steps: _steps,
            ),
          _ImportState.done  => _DoneView(onImportAnother: _pickAndImport),
          _ImportState.error => _ErrorView(error: _error ?? 'Unknown error', onRetry: _reset),
        },
      ),
    );
  }
}

enum _ImportState { idle, processing, done, error }

// ─── Idle State ──────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final VoidCallback onImport;
  const _IdleView({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Spacing.lg, Spacing.lg, Spacing.lg,
        Spacing.massive + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        // Hero card
        GestureDetector(
          onTap: onImport,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: Spacing.massive, horizontal: Spacing.xxl),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(Radii.xl),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
                style: BorderStyle.solid,
              ),
              boxShadow: AppShadows.elevated(context),
            ),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
                    ),
                    borderRadius: BorderRadius.circular(Radii.xl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: Spacing.xxl),
                Text(
                  'Select a PDF Document',
                  style: AppTextStyles.heading(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Browse your device, Downloads, Google Drive,\nor any connected storage',
                  style: AppTextStyles.body(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xxl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                    ),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Browse Files',
                        style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.xxl),

        // How it works
        Text('What happens next', style: AppTextStyles.subheading(context)),
        const SizedBox(height: Spacing.lg),
        _HowItWorksCard(
          step: 1, icon: Icons.text_snippet_outlined,
          title: 'Text extraction',
          body: 'Invoice data is extracted from the PDF locally on your device.',
        ),
        const SizedBox(height: Spacing.md),
        _HowItWorksCard(
          step: 2, icon: Icons.verified_outlined,
          title: 'ZIMRA fiscalization',
          body: 'The extracted data is sent to Fiscalize for ZIMRA submission and receipt generation.',
        ),
        const SizedBox(height: Spacing.md),
        _HowItWorksCard(
          step: 3, icon: Icons.qr_code_2_rounded,
          title: 'Fiscal stamp applied',
          body: 'QR code and verification data are stamped directly onto your PDF.',
        ),
        const SizedBox(height: Spacing.md),
        _HowItWorksCard(
          step: 4, icon: Icons.save_alt_rounded,
          title: 'Saved to Documents',
          body: 'The stamped fiscal document is saved and available in your Documents history.',
        ),
        const SizedBox(height: Spacing.xxl),

        // Tip card
        Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: context.primaryBg,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tip', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'You can also open any PDF from your Files app, WhatsApp, or email and choose "Open with Fiscalize Any" to fiscalize it instantly.',
                      style: AppTextStyles.body(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String body;
  const _HowItWorksCard({required this.step, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Spacing.lg),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(Radii.lg),
      border: Border.all(color: context.borderColor),
      boxShadow: AppShadows.card(context),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: context.primaryBg,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Center(
            child: Text('$step', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary,
            )),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(title, style: AppTextStyles.bodyMedium(context)),
                ],
              ),
              const SizedBox(height: 4),
              Text(body, style: AppTextStyles.body(context)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── Processing State ────────────────────────────────────────────────────────

class _ProcessingView extends StatefulWidget {
  final String? fileName;
  final ImportStep currentStep;
  final String currentLabel;
  final List<ImportStep> steps;

  const _ProcessingView({
    required this.fileName,
    required this.currentStep,
    required this.currentLabel,
    required this.steps,
  });

  @override
  State<_ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<_ProcessingView> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool _isCompleted(ImportStep step) {
    final currentIdx = widget.steps.indexOf(widget.currentStep);
    final stepIdx = widget.steps.indexOf(step);
    return stepIdx < currentIdx;
  }

  bool _isActive(ImportStep step) => step == widget.currentStep;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: 0.2 + _pulse.value * 0.25,
                      ),
                      blurRadius: 24 + _pulse.value * 16,
                      spreadRadius: 4 + _pulse.value * 6,
                    ),
                  ],
                ),
                child: child,
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: Spacing.xxl),
            if (widget.fileName != null) ...[
              Text(
                widget.fileName!,
                style: AppTextStyles.bodyMedium(context),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.sm),
            ],
            Text(
              'Fiscalizing document…',
              style: AppTextStyles.heading(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xxxl),

            // Steps
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(Radii.xl),
                border: Border.all(color: context.borderColor),
                boxShadow: AppShadows.card(context),
              ),
              child: Column(
                children: widget.steps.map((step) => _StepRow(
                  step: step,
                  isCompleted: _isCompleted(step),
                  isActive: _isActive(step),
                  pulse: _pulse,
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final ImportStep step;
  final bool isCompleted;
  final bool isActive;
  final Animation<double> pulse;

  const _StepRow({
    required this.step, required this.isCompleted,
    required this.isActive, required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? (context.isDark ? AppColors.successDark : AppColors.success)
        : isActive
            ? AppColors.primary
            : context.textM;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppDurations.normal, curve: AppCurves.spring,
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? (context.isDark ? AppColors.successDark.withValues(alpha: 0.2) : AppColors.successLight)
                  : isActive
                      ? context.primaryBg
                      : context.surfDim,
              border: Border.all(
                color: isCompleted
                    ? (context.isDark ? AppColors.successDark : AppColors.success)
                    : isActive ? AppColors.primary : context.borderColor,
                width: isActive ? 2 : 1,
              ),
            ),
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 16,
                    color: context.isDark ? AppColors.successDark : AppColors.success)
                : isActive
                    ? AnimatedBuilder(
                        animation: pulse,
                        builder: (context2, child2) => Center(
                          child: Container(
                            width: 8 + pulse.value * 4,
                            height: 8 + pulse.value * 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.7 + pulse.value * 0.3),
                            ),
                          ),
                        ),
                      )
                    : null,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              step.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Done State ──────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  final VoidCallback onImportAnother;
  const _DoneView({required this.onImportAnother});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.successBg,
                border: Border.all(
                  color: (context.isDark ? AppColors.successDark : AppColors.success).withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.15),
                    blurRadius: 24, offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 48,
                color: context.isDark ? AppColors.successDark : AppColors.success,
              ),
            ),
            const SizedBox(height: Spacing.xxl),
            Text('Document Fiscalized', style: AppTextStyles.heading(context)),
            const SizedBox(height: Spacing.sm),
            Text(
              'Your document has been fiscalized and saved.\nCheck the Documents tab to view it.',
              style: AppTextStyles.body(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xxxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onImportAnother,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Fiscalize Another Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.errorBg,
                border: Border.all(
                  color: (context.isDark ? AppColors.errorDark : AppColors.error).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: context.isDark ? AppColors.errorDark : AppColors.error,
              ),
            ),
            const SizedBox(height: Spacing.xxl),
            Text('Fiscalization Failed', style: AppTextStyles.heading(context)),
            const SizedBox(height: Spacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: context.errorBg,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: (context.isDark ? AppColors.errorDark : AppColors.error).withValues(alpha: 0.3)),
              ),
              child: Text(
                error,
                style: GoogleFonts.inter(
                  fontSize: 13, color: context.isDark ? AppColors.errorDark : AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Spacing.xxxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
