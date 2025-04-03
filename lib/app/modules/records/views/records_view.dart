import 'package:flutter/material.dart';
import 'package:podium/app/modules/records/views/records.dart';
import 'package:podium/root.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: Column(
          children: [
            const Text(
              'Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recordings are saved locally on your device',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Records(),
            ),
          ],
        ),
      ),
    );
  }
}
