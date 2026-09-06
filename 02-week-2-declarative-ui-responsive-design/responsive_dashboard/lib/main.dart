import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentDark = _themeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : _themeMode == ThemeMode.dark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: _themeMode,
      home: DashboardPage(
        isDark: isCurrentDark,
        currentMode: _themeMode,
        onDarkChanged: _toggleTheme,
        onResetToSystem: () => setState(() => _themeMode = ThemeMode.system),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.currentMode,
    required this.onDarkChanged,
    required this.onResetToSystem,
    super.key,
  });

  final bool isDark;
  final ThemeMode currentMode;
  final ValueChanged<bool> onDarkChanged;
  final VoidCallback onResetToSystem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          // Tombol untuk mengembalikan ke mode sistem
          Semantics(
            label: 'Kembalikan tema ke pengaturan sistem',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.brightness_auto),
              tooltip: 'Reset ke ThemeMode.system',
              onPressed: onResetToSystem,
            ),
          ),
          Row(
            children: [
              Semantics(
                excludeSemantics:
                    true,
                child: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              ),
              const SizedBox(width: 4),
              Semantics(
                label: 'Alihkan mode gelap',
                toggled: isDark,
                child: CupertinoSwitch(value: isDark, onChanged: onDarkChanged),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final int columns;
          if (constraints.maxWidth >= 900) {
            columns = 3;
          } else if (constraints.maxWidth >= 600) {
            columns = 2;
          } else {
            columns = 1;
          }

          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.6,
            children: const [
              DashboardCard(
                title: 'Assignments',
                value: '8',
                semanticLabel: 'Tugas: 8 tersisa',
              ),
              DashboardCard(
                title: 'Attendance',
                value: '92%',
                semanticLabel: 'Tingkat kehadiran: 92 persen',
              ),
              DashboardCard(
                title: 'Portfolio',
                value: 'Ready',
                semanticLabel: 'Status portofolio: Siap',
              ),
              DashboardCard(
                title: 'Current week',
                value: '02',
                semanticLabel: 'Minggu pembelajaran saat ini: Minggu ke-2',
              ),
            ],
          );
        },
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.title,
    required this.value,
    this.semanticLabel,
    super.key,
  });

  final String title;
  final String value;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Semantics(
        container: true,
        label: semanticLabel ?? '$title: $value',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(child: Text(title)),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
