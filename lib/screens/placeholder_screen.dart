import 'package:flutter/material.dart';
import 'home_screen.dart' show brown, cream;

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: brown),
            const SizedBox(height: 12),
            Text('$title: coming soon',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}