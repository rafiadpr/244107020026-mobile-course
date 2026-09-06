import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

const double kWideBreakpoint = 700.0;

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academic Overview',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: AcademicOverviewPage(
        isDark: _isDark,
        onThemeChanged: (val) => setState(() => _isDark = val),
      ),
    );
  }
}

class AcademicOverviewPage extends StatelessWidget {
  const AcademicOverviewPage({
    required this.isDark,
    required this.onThemeChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Row(
            children: [
              Semantics(
                excludeSemantics: true,
                child: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Alihkan mode gelap',
                toggled: isDark,
                child: CupertinoSwitch(
                  value: isDark,
                  onChanged: onThemeChanged,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= kWideBreakpoint;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profil Mahasiswa
                _buildProfileHeader(theme),
                const SizedBox(height: 20),

                // Area Kartu Informasi Responsif
                if (!isWide)
                  // 1 Kolom untuk layar sempit (< 700px)
                  const Column(
                    children: [
                      InfoCard(
                        title: 'IPK Semester',
                        value: '3.85',
                        semanticLabel: 'Indeks Prestasi Semester: 3 koma 85',
                      ),
                      SizedBox(height: 12),
                      InfoCard(
                        title: 'SKS Ditempuh',
                        value: '78 / 144',
                        semanticLabel: 'SKS ditempuh: 78 dari 144 SKS',
                      ),
                      SizedBox(height: 12),
                      InfoCard(
                        title: 'Kehadiran Kuliah',
                        value: '95%',
                        semanticLabel: 'Persentase kehadiran: 95 persen',
                      ),
                      SizedBox(height: 12),
                      InfoCard(
                        title: 'Tugas Menunggu',
                        value: '3',
                        semanticLabel: 'Tugas menunggu dikerjakan: 3 tugas',
                      ),
                    ],
                  )
                else
                  // 2 Kolom untuk layar lebar (>= 700px)
                  const Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InfoCard(
                              title: 'IPK Semester',
                              value: '3.85',
                              semanticLabel: 'Indeks Prestasi Semester: 3 koma 85',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: InfoCard(
                              title: 'SKS Ditempuh',
                              value: '78 / 144',
                              semanticLabel: 'SKS ditempuh: 78 dari 144 SKS',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InfoCard(
                              title: 'Kehadiran Kuliah',
                              value: '95%',
                              semanticLabel: 'Persentase kehadiran: 95 persen',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: InfoCard(
                              title: 'Tugas Menunggu',
                              value: '3',
                              semanticLabel: 'Tugas menunggu dikerjakan: 3 tugas',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              'M',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mahasiswa Aktif',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Teknologi Informasi — Semester 4',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
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
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: semanticLabel ?? '$title: $value',
      excludeSemantics: true,
      child: Card(
        elevation: 1,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}