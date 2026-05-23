import 'package:flutter/material.dart';

class ArchivedPatientsScreen extends StatelessWidget {
  const ArchivedPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Patients')),
      body: const Center(child: Text('Archived Patients - Coming soon')),
    );
  }
}
