import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BotFutApp());
}

class BotFutApp extends StatelessWidget {
  const BotFutApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BotFut',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
