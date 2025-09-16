import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(ExerciseApp());
}

class ExerciseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise AI App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(),
    );
  }
}
