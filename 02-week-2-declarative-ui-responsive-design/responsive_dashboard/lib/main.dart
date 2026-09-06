import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// refactor 3
const double kWideBreakpoint = 700.0;

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (val) => setState(() => isDark = val),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          ExcludeSemantics(
            child: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Alihkan mode gelap',
            toggled: isDark,
            child: CupertinoSwitch(
              value: isDark,
              onChanged: onDarkChanged,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // refactor 3
          final columns = constraints.maxWidth >= kWideBreakpoint ? 2 : 1;

          return Column(
            children: [
              // Header Profil via ListTile (Ringkas & Rapi)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Semantics(
                  container: true,
                  label: 'Profil Mahasiswa: Teknologi Informasi Semester 4',
                  child: const Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        'Rafi Adrian Prasetya',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('NIM : 244107020026'),
                    ),
                  ),
                ),
              ),

              // Area Kartu Responsif
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.6,
                  // refactor 1
                  children: const [
                    InfoCard(title: 'IPK Semester', value: '3.85'),
                    InfoCard(title: 'SKS Ditempuh', value: '78 / 144'),
                    InfoCard(title: 'Kehadiran Kuliah', value: '95%'),
                    InfoCard(title: 'Tugas Menunggu', value: '3'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// refactor 1
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    super.key,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    // refactor 2
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: 'Kategori $title, nilai $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  // refactor 2
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                value,
                // refactor 2
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