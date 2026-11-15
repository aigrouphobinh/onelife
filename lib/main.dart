import 'package:flutter/material.dart';
import 'package:onelife/src/design_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OneLifeApp());
}

class OneLifeApp extends StatelessWidget {
  const OneLifeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'OneLife',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8054E6)),
          scaffoldBackgroundColor: const Color(0xFFF8F3FF),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF8F3FF),
            foregroundColor: Color(0xFF21183C),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8054E6),
              minimumSize: const Size(48, 44),
            ),
          ),
        ),
        home: const OneLifeDesignShell(),
      );
}
