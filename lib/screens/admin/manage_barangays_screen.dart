import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ManageBarangaysScreen extends StatefulWidget {
  const ManageBarangaysScreen({Key? key}) : super(key: key);

  @override
  State<ManageBarangaysScreen> createState() => _ManageBarangaysScreenState();
}

class _ManageBarangaysScreenState extends State<ManageBarangaysScreen> {
  List<dynamic> _barangays = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBarangays();
  }

  Future<void> _fetchBarangays() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.instance.get('/barangays');
      
      final barangaysData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : (response.data is List ? response.data : []);
      
      setState(() => _barangays = barangaysData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load barangays: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredBarangays {
    return _barangays.where((b) {
      final name = (b['name'] ?? '').toLowerCase();
      final captain = (b['barangay_captain'] ?? '').toLowerCase();
      final contact = (b['contact_number'] ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          captain.contains(_searchQuery.toLowerCase()) ||
          contact.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  int get _totalPopulation {
    return _barangays.fold(0, (sum, b) => sum + (b['population'] ?? 0) as int);
  }

  int get _activeCaptains {
    return _barangays.where((b) => b['barangay_captain'] != null && b['barangay_captain'].toString().trim().isNotEmpty).length;
  }

  void _showViewModal(dynamic barangay) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Barangay Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailCard('Barangay Name', barangay['name'] ?? 'N/A', Color(0xFF10B981)),
                    _buildDetailCard('Address', barangay['address'] ?? 'N/A', Color(0xFF3B82F6)),
                    _buildDetailCard('Barangay Captain', barangay['barangay_captain'] ?? 'N/A', Color(0xFF8B5CF6)),
                    _buildDetailCard('Health Officer', barangay['health_officer'] ?? 'N/A', Color(0xFFEC4899)),
                    _buildDetailCard('Contact Number', barangay['contact_number'] ?? 'N/A', Color(0xFFF59E0B)),
                    _buildDetailCard('Coverage Area', barangay['coverage_area'] ?? 'N/A', Color(0xFF14B8A6)),
                    _buildDetailCard('Total Population', barangay['population']?.toString() ?? 'N/A', Color(0xFF6366F1)),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Population Breakdown', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                          SizedBox(height: 8),
                          Text('Male: ${barangay['population_male']?.toString() ?? 'N/A'}', style: TextStyle(color: Color(0xFF1F2937))),
                          Text('Female: ${barangay['population_female']?.toString() ?? 'N/A'}', style: TextStyle(color: Color(0xFF1F2937))),
                          Text('Children: ${barangay['population_children']?.toString() ?? 'N/A'}', style: TextStyle(color: Color(0xFF1F2937))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }

  void _showEditModal(dynamic barangay) {
    final nameController = TextEditingController(text: barangay['name']);
    final addressController = TextEditingController(text: barangay['address'] ?? '');
    final contactController = TextEditingController(text: barangay['contact_number'] ?? '');
    final captainController = TextEditingController(text: barangay['barangay_captain'] ?? '');
    final healthOfficerController = TextEditingController(text: barangay['health_officer'] ?? '');
    final populationController = TextEditingController(text: barangay['population']?.toString() ?? '');
    final populationMaleController = TextEditingController(text: barangay['population_male']?.toString() ?? '');
    final populationFemaleController = TextEditingController(text: barangay['population_female']?.toString() ?? '');
    final populationChildrenController = TextEditingController(text: barangay['population_children']?.toString() ?? '');
    final coverageAreaController = TextEditingController(text: barangay['coverage_area'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Edit Barangay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Basic Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          SizedBox(height: 12),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Barangay Name *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: addressController,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: contactController,
                            decoration: InputDecoration(
                              labelText: 'Contact Number',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: coverageAreaController,
                            decoration: InputDecoration(
                              labelText: 'Coverage Area',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Officials', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                          SizedBox(height: 12),
                          TextField(
                            controller: captainController,
                            decoration: InputDecoration(
                              labelText: 'Barangay Captain',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: healthOfficerController,
                            decoration: InputDecoration(
                              labelText: 'Health Officer',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Population Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                          SizedBox(height: 12),
                          TextField(
                            controller: populationController,
                            decoration: InputDecoration(
                              labelText: 'Total Population',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: populationMaleController,
                            decoration: InputDecoration(
                              labelText: 'Male Population',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: populationFemaleController,
                            decoration: InputDecoration(
                              labelText: 'Female Population',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: populationChildrenController,
                            decoration: InputDecoration(
                              labelText: 'Children Population',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateBarangay(
                              barangay['id'],
                              nameController.text,
                              addressController.text,
                              contactController.text,
                              captainController.text,
                              healthOfficerController.text,
                              populationController.text,
                              populationMaleController.text,
                              populationFemaleController.text,
                              populationChildrenController.text,
                              coverageAreaController.text,
                            ),
                            child: Text('Update'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBarangay(
    int id,
    String name,
    String address,
    String contact,
    String captain,
    String healthOfficer,
    String population,
    String populationMale,
    String populationFemale,
    String populationChildren,
    String coverageArea,
  ) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barangay name is required')),
      );
      return;
    }

    try {
      await ApiService.instance.put('/barangays/$id', data: {
        'name': name,
        'address': address.isEmpty ? null : address,
        'contact_number': contact.isEmpty ? null : contact,
        'barangay_captain': captain.isEmpty ? null : captain,
        'health_officer': healthOfficer.isEmpty ? null : healthOfficer,
        'population': population.isEmpty ? null : int.tryParse(population),
        'population_male': populationMale.isEmpty ? null : int.tryParse(populationMale),
        'population_female': populationFemale.isEmpty ? null : int.tryParse(populationFemale),
        'population_children': populationChildren.isEmpty ? null : int.tryParse(populationChildren),
        'coverage_area': coverageArea.isEmpty ? null : coverageArea,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barangay updated successfully'), backgroundColor: Colors.green),
      );
      _fetchBarangays();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBarangays = _filteredBarangays;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Manage Barangays', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF10B981)),
            onPressed: _fetchBarangays,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Barangays', _barangays.length, Color(0xFF10B981), Icons.business),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Total Population', _totalPopulation, Color(0xFF3B82F6), Icons.people),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Active Captains', _activeCaptains, Color(0xFF8B5CF6), Icons.person_pin),
                ),
              ],
            ),
          ),
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, captain, or contact...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                ),
                filled: true,
                fillColor: Color(0xFFF9FAFB),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Barangays List
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : filteredBarangays.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on_outlined, size: 80, color: Colors.grey.shade300),
                            SizedBox(height: 16),
                            Text('No barangays found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredBarangays.length,
                        itemBuilder: (context, index) => _buildBarangayCard(filteredBarangays[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildBarangayCard(dynamic barangay) {
    final name = barangay['name'] ?? '';
    final address = barangay['address'] ?? 'N/A';
    final captain = barangay['barangay_captain'] ?? 'N/A';
    final healthOfficer = barangay['health_officer'] ?? 'N/A';
    final contact = barangay['contact_number'] ?? 'N/A';
    final population = barangay['population'];
    final populationMale = barangay['population_male'] ?? 0;
    final populationFemale = barangay['population_female'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF10B981),
                  child: Text(name[0].toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      SizedBox(height: 2),
                      Text(address, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Color(0xFF6B7280)),
                SizedBox(width: 6),
                Expanded(child: Text(captain, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.medical_services, size: 14, color: Color(0xFF6B7280)),
                SizedBox(width: 6),
                Expanded(child: Text('Health Officer: $healthOfficer', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Color(0xFF6B7280)),
                SizedBox(width: 6),
                Text(contact, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Color(0xFF6B7280)),
                SizedBox(width: 6),
                Text(
                  population != null ? '${population.toString()} (M: $populationMale / F: $populationFemale)' : 'N/A',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showViewModal(barangay),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF3B82F6),
                      side: BorderSide(color: Color(0xFF3B82F6)),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditModal(barangay),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
