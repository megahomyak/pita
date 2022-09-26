import 'package:flutter/material.dart';
import 'authentication.dart';

void main() {
  runApp(const Pita());
}

class Pita extends StatelessWidget {
  const Pita({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Pita', home: AuthenticationScreen());
  }
}
