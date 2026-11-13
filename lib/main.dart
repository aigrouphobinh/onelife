import 'package:flutter/material.dart';
import 'package:onelife/src/note_repository.dart';
import 'package:onelife/src/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(OneLifeApp(repository: NoteRepository()));
}

class OneLifeApp extends StatelessWidget {
  const OneLifeApp({super.key, required this.repository});
  final NoteRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'OneLife',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: HomePage(repository: repository),
      );
}
