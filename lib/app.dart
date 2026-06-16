import 'package:flutter/material.dart';
import 'core/models/fiscal_document.dart';
import 'core/theme/app_theme.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/document/document_detail_screen.dart';

class FiscalizeAnyApp extends StatelessWidget {
  const FiscalizeAnyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FiscalizeAny',
      theme: appTheme,
      darkTheme: appThemeDark,
      home: const _Shell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  void _openDocument(FiscalDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentDetailScreen(doc: doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HistoryScreen(onOpen: _openDocument),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
