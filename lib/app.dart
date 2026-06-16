import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/models/fiscal_document.dart';
import 'core/theme/app_theme.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/document/document_detail_screen.dart';

class FiscalizeAnyApp extends StatefulWidget {
  const FiscalizeAnyApp({super.key});

  @override
  State<FiscalizeAnyApp> createState() => _FiscalizeAnyAppState();
}

class _FiscalizeAnyAppState extends State<FiscalizeAnyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fiscalize Any',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: AppShell(
        onThemeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  const AppShell({super.key, required this.onThemeChanged});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  void _openDocument(FiscalDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentDetailScreen(doc: doc)),
    );
  }

  void _setTab(int i) {
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(onThemeChanged: widget.onThemeChanged),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = 80.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            bottom: navBarHeight,
            child: IndexedStack(
              index: _tab,
              children: [
                HistoryScreen(onOpen: _openDocument, onSettingsTap: _openSettings),
                const _SetupGuidePage(),
              ],
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomNavBar(currentIndex: _tab, onTap: _setTab),
          ),
        ],
      ),
    );
  }
}

// ─── Setup / How-to Page ────────────────────────────────────────────────────

class _SetupGuidePage extends StatelessWidget {
  const _SetupGuidePage();

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.settings_rounded, 'Configure credentials', 'Tap Settings → enter your Fiscalize API URL, Device API Key, and Secret.'),
      (Icons.print_rounded, 'Enable virtual printer', 'Go to Android Settings → Connected Devices → Printing → enable "Fiscalize Fiscal Printer".'),
      (Icons.picture_as_pdf_rounded, 'Print any invoice', 'From any billing or POS app, tap Print and select "Fiscalize Fiscal Printer".'),
      (Icons.verified_rounded, 'Fiscal stamp applied', 'The app extracts text, fiscalizes with ZIMRA, stamps the QR code, then saves or prints your document.'),
    ];

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surf,
        title: Text('How It Works', style: AppTextStyles.subheading(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg, Spacing.lg, Spacing.lg,
          Spacing.lg + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(Spacing.xxl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              ),
              borderRadius: BorderRadius.circular(Radii.xl),
              boxShadow: AppShadows.elevated(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Fiscalize Any',
                  style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Virtual fiscal printer for Android.\nPrint from any app — we handle ZIMRA.',
                  style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xxl),
          Text('Get started in 4 steps', style: AppTextStyles.subheading(context)),
          const SizedBox(height: Spacing.lg),
          ...steps.asMap().entries.map((e) => _StepCard(
            index: e.key + 1,
            icon: e.value.$1,
            title: e.value.$2,
            body: e.value.$3,
          )),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final String body;
  const _StepCard({required this.index, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Container(
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: context.primaryBg,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: AppColors.primary),
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
      ),
    );
  }
}

// ─── Bottom Nav Bar ──────────────────────────────────────────────────────────

class _BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDocsActive = widget.currentIndex == 0;

    return Container(
      height: 80 + bottomPadding,
      decoration: BoxDecoration(
        color: context.surf,
        border: Border(top: BorderSide(color: context.borderColor, width: 0.5)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Row(
              children: [
                Expanded(child: _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Documents',
                  isActive: isDocsActive,
                  onTap: () => widget.onTap(0),
                )),
                const Expanded(child: SizedBox()),
                Expanded(child: _NavItem(
                  icon: Icons.help_outline_rounded,
                  activeIcon: Icons.help_rounded,
                  label: 'Setup',
                  isActive: widget.currentIndex == 1,
                  onTap: () => widget.onTap(1),
                )),
              ],
            ),
          ),
          // Floating print/fiscal button
          Positioned(
            top: -20, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onTap(0);
                },
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    final glow = isDocsActive ? 0.0 : 0.08 + _pulseController.value * 0.12;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!isDocsActive)
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: glow),
                              blurRadius: 20 + _pulseController.value * 10,
                              spreadRadius: 3 + _pulseController.value * 4,
                            ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: isDocsActive ? 0.35 : 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
                      ),
                      border: Border.all(color: context.surf, width: 4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 26),
                        Text(
                          'FISCAL',
                          style: GoogleFonts.inter(
                            fontSize: 7.5, fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.9), letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.activeIcon,
    required this.label, required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : context.textM;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.0 : 0.85,
              duration: AppDurations.fast,
              curve: AppCurves.spring,
              child: Icon(isActive ? activeIcon : icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: AppDurations.fast, curve: AppCurves.spring,
              width: isActive ? 4 : 0, height: isActive ? 4 : 0,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
