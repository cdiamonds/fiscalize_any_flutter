import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SettingsService();

  late final TextEditingController _apiUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _apiSecret;
  late final TextEditingController _printerIp;
  late final TextEditingController _printerPort;
  late final TextEditingController _deviceId;
  String _outputMode = 'print_and_save';
  ThemeMode _themeMode = ThemeMode.system;

  bool _loading = true;
  bool _saving = false;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _apiUrl = TextEditingController();
    _apiKey = TextEditingController();
    _apiSecret = TextEditingController();
    _printerIp = TextEditingController();
    _printerPort = TextEditingController(text: '9100');
    _deviceId = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _service.load();
    setState(() {
      _apiUrl.text = s.apiUrl;
      _apiKey.text = s.apiKey;
      _apiSecret.text = s.apiSecret;
      _printerIp.text = s.printerIp;
      _printerPort.text = s.printerPort.toString();
      _deviceId.text = s.deviceId?.toString() ?? '';
      _outputMode = s.outputMode;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.save(AppSettings(
        apiUrl: _apiUrl.text.trim().replaceAll(RegExp(r'/$'), ''),
        apiKey: _apiKey.text.trim(),
        apiSecret: _apiSecret.text.trim(),
        printerIp: _printerIp.text.trim(),
        printerPort: int.tryParse(_printerPort.text) ?? 9100,
        deviceId: int.tryParse(_deviceId.text),
        outputMode: _outputMode,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _apiUrl.dispose(); _apiKey.dispose(); _apiSecret.dispose();
    _printerIp.dispose(); _printerPort.dispose(); _deviceId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surf,
        title: Text('Settings', style: AppTextStyles.subheading(context)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _save,
                child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Spacing.lg, Spacing.lg, Spacing.lg,
            Spacing.massive + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            // ── API ────────────────────────────────────────────────
            _Section(title: 'Fiscalize API', icon: Icons.cloud_outlined),
            const SizedBox(height: Spacing.md),
            _Field(
              controller: _apiUrl,
              label: 'API Base URL',
              hint: 'https://api.yourfiscalize.com',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: Spacing.md),
            _Field(
              controller: _apiKey,
              label: 'Device API Key',
              icon: Icons.vpn_key_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: Spacing.md),
            _PasswordField(
              controller: _apiSecret,
              label: 'Device API Secret',
              obscure: _obscureSecret,
              onToggle: () => setState(() => _obscureSecret = !_obscureSecret),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: Spacing.md),
            _Field(
              controller: _deviceId,
              label: 'Device ID',
              hint: 'Leave blank to use company default',
              icon: Icons.devices_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: Spacing.xxl),

            // ── Printer ────────────────────────────────────────────
            _Section(title: 'Real Printer (RAW TCP)', icon: Icons.print_outlined),
            const SizedBox(height: Spacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _Field(
                    controller: _printerIp,
                    label: 'Printer IP',
                    hint: '192.168.1.100',
                    icon: Icons.router_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: _Field(
                    controller: _printerPort,
                    label: 'Port',
                    icon: Icons.lan_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => (int.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xxl),

            // ── Output mode ────────────────────────────────────────
            _Section(title: 'After Fiscalization', icon: Icons.tune_outlined),
            const SizedBox(height: Spacing.md),
            ..._outputModes.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _ModeCard(
                label: e.value,
                selected: _outputMode == e.key,
                onTap: () => setState(() => _outputMode = e.key),
              ),
            )),
            const SizedBox(height: Spacing.xxl),

            // ── Appearance ─────────────────────────────────────────
            _Section(title: 'Appearance', icon: Icons.palette_outlined),
            const SizedBox(height: Spacing.md),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  _ThemeTile(
                    label: 'System default',
                    icon: Icons.brightness_auto_rounded,
                    selected: _themeMode == ThemeMode.system,
                    onTap: () { setState(() => _themeMode = ThemeMode.system); widget.onThemeChanged(ThemeMode.system); },
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  _ThemeTile(
                    label: 'Light',
                    icon: Icons.light_mode_rounded,
                    selected: _themeMode == ThemeMode.light,
                    onTap: () { setState(() => _themeMode = ThemeMode.light); widget.onThemeChanged(ThemeMode.light); },
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  _ThemeTile(
                    label: 'Dark',
                    icon: Icons.dark_mode_rounded,
                    selected: _themeMode == ThemeMode.dark,
                    onTap: () { setState(() => _themeMode = ThemeMode.dark); widget.onThemeChanged(ThemeMode.dark); },
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xxxl),

            // ── Save button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving…' : 'Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _outputModes = {
    'print_and_save': 'Print + Save to device',
    'print': 'Print only',
    'save': 'Save to device only',
    'ask': 'Ask each time',
  };
}

// ─── Reusable form components ────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  const _Section({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
      )),
    ],
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller, required this.label,
    required this.icon, this.hint, this.keyboardType, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      prefixIcon: Icon(icon, size: 20),
    ),
    keyboardType: keyboardType,
    validator: validator,
  );
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller, required this.label,
    required this.obscure, required this.onToggle, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
        onPressed: onToggle,
      ),
    ),
    validator: validator,
  );
}

class _ModeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: AppDurations.fast, curve: AppCurves.spring,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      decoration: BoxDecoration(
        color: selected ? context.primaryBg : context.cardColor,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: selected ? AppColors.primary.withValues(alpha: 0.5) : context.borderColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppDurations.fast,
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : context.textM,
                width: selected ? 5 : 1.5,
              ),
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Text(label, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    ),
  );
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: selected ? AppColors.primary : context.textS),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(label, style: selected ? AppTextStyles.bodyMedium(context) : AppTextStyles.body(context))),
          if (selected) const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
        ],
      ),
    ),
  );
}
