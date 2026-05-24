import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BarangayDropdown extends StatefulWidget {
  final int? selectedBarangayId;
  final Function(int?) onChanged;
  final bool required;

  const BarangayDropdown({
    Key? key,
    this.selectedBarangayId,
    required this.onChanged,
    this.required = true,
  }) : super(key: key);

  @override
  State<BarangayDropdown> createState() => _BarangayDropdownState();
}

class _BarangayDropdownState extends State<BarangayDropdown> {
  List<Map<String, dynamic>> barangays = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBarangays();
  }

  Future<void> fetchBarangays() async {
    try {
      final response = await ApiService.instance.get('/user/barangays');
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          barangays = List<Map<String, dynamic>>.from(data['barangays'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to fetch barangays: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: isLoading
          ? const LinearProgressIndicator()
          : DropdownButtonFormField<int>(
              value: widget.selectedBarangayId,
              decoration: const InputDecoration(
                labelText: 'Barangay',
                border: OutlineInputBorder(),
              ),
              items: barangays.map((barangay) {
                return DropdownMenuItem<int>(
                  value: barangay['id'],
                  child: Text(barangay['name'] ?? ''),
                );
              }).toList(),
              onChanged: widget.onChanged,
              validator: widget.required
                  ? (value) => value == null ? 'Please select a barangay' : null
                  : null,
            ),
    );
  }
}
