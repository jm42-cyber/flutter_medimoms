# Fix Barangay Dropdown in All Program Screens

## Summary
The barangay field in all 4 program screens (Immunization, Maternal Care, Family Planning, Senior Citizen) needs to be changed from a text field to a dropdown that shows only the midwife's assigned barangays.

## What's Already Done
✅ Immunization Screen - Already has barangay dropdown working

## What Needs to Be Fixed
❌ Maternal Care Screen
❌ Family Planning Screen  
❌ Senior Citizen Screen

## How to Fix Each Screen

### Step 1: Add state variables
Find the state variables section and add:
```dart
List<Map<String, dynamic>> barangays = [];
int? selectedBarangayId;
```

### Step 2: Add fetchBarangays method
Add this method after initState:
```dart
Future<void> fetchBarangays() async {
  try {
    final response = await ApiService.instance.get('/user/barangays');
    if (response.statusCode == 200) {
      final data = response.data;
      setState(() {
        barangays = List<Map<String, dynamic>>.from(data['barangays'] ?? []);
      });
    }
  } catch (e) {
    print('Failed to fetch barangays: $e');
  }
}
```

### Step 3: Call fetchBarangays in initState
```dart
@override
void initState() {
  super.initState();
  fetchBarangays();  // Add this line
  fetchRecords();
}
```

### Step 4: Update _populateForm method
Find where barangay is populated and replace with:
```dart
if (record['barangay'] is Map) {
  selectedBarangayId = record['barangay']['id'];
} else if (record['barangay_id'] != null) {
  selectedBarangayId = record['barangay_id'];
}
```

### Step 5: Update _clearForm method
Add this line:
```dart
selectedBarangayId = null;
```

### Step 6: Update _saveRecord method
Replace `'barangay': barangayController.text,` with:
```dart
'barangay_id': selectedBarangayId,
```

### Step 7: Replace text field with dropdown
In the step where barangay field is shown, replace:
```dart
_buildTextField('Barangay', barangayController, required: true),
```

With:
```dart
_buildBarangayDropdown(),
```

### Step 8: Add _buildBarangayDropdown method
Add this method at the end before the closing brace:
```dart
Widget _buildBarangayDropdown() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<int>(
      value: selectedBarangayId,
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
      onChanged: (value) {
        setState(() {
          selectedBarangayId = value;
        });
      },
      validator: (value) => value == null ? 'Please select a barangay' : null,
    ),
  );
}
```

## Files to Update
1. `lib/screens/modules/maternal_care_screen.dart`
2. `lib/screens/modules/family_planning_screen.dart`
3. `lib/screens/modules/senior_citizen_screen.dart`

## Testing
After updating each file:
1. Hot restart the Flutter app
2. Try adding a new patient record
3. Verify the barangay dropdown shows your assigned barangays
4. Verify you can select a barangay and save successfully
