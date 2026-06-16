import 'package:flutter/material.dart';
import '../../core/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
        apiUrl: _apiUrl.text.trim().trimRight().replaceAll(RegExp(r'/$'), ''),
        apiKey: _apiKey.text.trim(),
        apiSecret: _apiSecret.text.trim(),
        printerIp: _printerIp.text.trim(),
        printerPort: int.tryParse(_printerPort.text) ?? 9100,
        deviceId: int.tryParse(_deviceId.text),
        outputMode: _outputMode,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _apiUrl.dispose();
    _apiKey.dispose();
    _apiSecret.dispose();
    _printerIp.dispose();
    _printerPort.dispose();
    _deviceId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader('Fiscalize API'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apiUrl,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'https://api.yourfiscalize.com',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apiKey,
              decoration: const InputDecoration(
                labelText: 'Device API Key',
                prefixIcon: Icon(Icons.key),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apiSecret,
              obscureText: _obscureSecret,
              decoration: InputDecoration(
                labelText: 'Device API Secret',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureSecret ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deviceId,
              decoration: const InputDecoration(
                labelText: 'Device ID (optional)',
                hintText: 'Leave blank to use company default',
                prefixIcon: Icon(Icons.devices),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _SectionHeader('Real Printer'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _printerIp,
                    decoration: const InputDecoration(
                      labelText: 'Printer IP Address',
                      hintText: '192.168.1.100',
                      prefixIcon: Icon(Icons.print),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _printerPort,
                    decoration: const InputDecoration(labelText: 'Port'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (int.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader('After Fiscalization'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _outputModes.entries.map((e) => ChoiceChip(
                label: Text(e.value),
                selected: _outputMode == e.key,
                onSelected: (_) => setState(() => _outputMode = e.key),
              )).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
