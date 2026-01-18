# Task 7: Vendor Profile Cuisine Selection

## Status: Complete

## Overview
Allow vendors to select their cuisine categories during profile setup. Vendors can choose up to 5 cuisines that describe their food offerings, helping customers find them through filtering.

---

## Files

### Created: `lib/screens/vendor/cuisine_selection_screen.dart`
### Modified: `lib/screens/vendor/vendor_home.dart`

---

## Cuisine Selection Screen

### Location: `lib/screens/vendor/cuisine_selection_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/cuisine_categories.dart';

class CuisineSelectionScreen extends StatefulWidget {
  final List<String> initialSelection;

  const CuisineSelectionScreen({
    super.key,
    this.initialSelection = const [],
  });

  @override
  State<CuisineSelectionScreen> createState() => _CuisineSelectionScreenState();
}

class _CuisineSelectionScreenState extends State<CuisineSelectionScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  late Set<String> _selectedCuisines;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCuisines = Set.from(widget.initialSelection);
  }

  void _toggleCuisine(String cuisine) {
    setState(() {
      if (_selectedCuisines.contains(cuisine)) {
        _selectedCuisines.remove(cuisine);
      } else {
        if (_selectedCuisines.length < 5) {
          _selectedCuisines.add(cuisine);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 5 cuisines allowed'),
            ),
          );
        }
      }
    });
  }

  Future<void> _save() async {
    final vendorId = _authService.currentUser?.uid;
    if (vendorId == null) return;

    if (_selectedCuisines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one cuisine'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _databaseService.updateVendorProfile(vendorId, {
        'cuisineTags': _selectedCuisines.toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuisines updated')),
        );
        Navigator.pop(context, _selectedCuisines.toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
```

---

## UI Components

### Instructions Banner

```dart
Container(
  padding: const EdgeInsets.all(16),
  color: Colors.orange.shade50,
  child: Row(
    children: [
      Icon(Icons.info_outline, color: Colors.orange.shade800),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          'Select up to 5 cuisines that describe your food. '
          'This helps customers find you.',
          style: TextStyle(color: Colors.orange.shade900),
        ),
      ),
    ],
  ),
)
```

### Selection Counter

```dart
Padding(
  padding: const EdgeInsets.all(16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        '${_selectedCuisines.length} / 5 selected',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      if (_selectedCuisines.isNotEmpty)
        TextButton(
          onPressed: () {
            setState(() => _selectedCuisines.clear());
          },
          child: const Text('Clear All'),
        ),
    ],
  ),
)
```

### Cuisine Grid

```dart
GridView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 2.5,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemCount: cuisineCategories.length,
  itemBuilder: (context, index) {
    final cuisine = cuisineCategories[index];
    final isSelected = _selectedCuisines.contains(cuisine);

    return InkWell(
      onTap: () => _toggleCuisine(cuisine),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.shade100
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                cuisine,
                style: TextStyle(
                  color: isSelected
                      ? Colors.orange.shade900
                      : Colors.grey.shade800,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  },
)
```

---

## Visual Layout

```
┌─────────────────────────────────────────────────────────────┐
│                     Select Cuisines                     [←] │
├─────────────────────────────────────────────────────────────┤
│ ℹ️ Select up to 5 cuisines that describe your food.        │
│    This helps customers find you.                           │
├─────────────────────────────────────────────────────────────┤
│ 3 / 5 selected                              [Clear All]     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ ✓ South Indian  │  │   North Indian  │                  │
│  └─────────────────┘  └─────────────────┘                  │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ ✓ Chinese       │  │   Street Food   │                  │
│  └─────────────────┘  └─────────────────┘                  │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │   Biryani       │  │ ✓ Beverages     │                  │
│  └─────────────────┘  └─────────────────┘                  │
│                         ...                                 │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│              [ Save Cuisines ]                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Vendor Home Integration

### Added Import

```dart
import 'cuisine_selection_screen.dart';
```

### Cuisine Card Widget

```dart
Widget _buildCuisineCard() {
  final cuisines = _vendorProfile?.cuisineTags ?? [];

  return Card(
    child: InkWell(
      onTap: () async {
        final result = await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(
            builder: (context) => CuisineSelectionScreen(
              initialSelection: cuisines,
            ),
          ),
        );

        if (result != null) {
          // Reload profile to show updated cuisines
          final profile = await _databaseService.getVendorProfile(
            _authService.currentUser!.uid,
          );
          if (mounted) {
            setState(() {
              _vendorProfile = profile;
            });
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.category,
                color: Colors.purple.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuisine Types',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cuisines.isEmpty
                        ? 'Select your cuisine types'
                        : cuisines.join(', '),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Build Method Integration

```dart
// In build() method, after _buildMenuCard():
const SizedBox(height: 12),
_buildCuisineCard(),
```

---

## Selection States

### Unselected Cuisine Tile
- Grey background (`Colors.grey.shade100`)
- Grey border (`Colors.grey.shade300`)
- Normal font weight
- No checkmark icon

### Selected Cuisine Tile
- Orange background (`Colors.orange.shade100`)
- Orange border with 2px width
- Bold font weight
- Checkmark icon (`Icons.check_circle`)

---

## Validation Rules

| Rule | Implementation |
|------|----------------|
| Maximum 5 cuisines | `if (_selectedCuisines.length < 5)` |
| Minimum 1 cuisine | Check in `_save()` before Firestore update |
| User not logged in | Early return if `vendorId == null` |

---

## Firestore Update

```dart
await _databaseService.updateVendorProfile(vendorId, {
  'cuisineTags': _selectedCuisines.toList(),
});
```

Updates the `cuisineTags` array field in `vendor_profiles/{vendorId}` document.

---

## Navigation Flow

```
Vendor Home
    │
    ├── Tap "Cuisine Types" card
    │           │
    │           ▼
    │   CuisineSelectionScreen
    │           │
    │           ├── Select cuisines
    │           ├── Tap "Save Cuisines"
    │           │
    │           ▼
    │   Navigator.pop(context, _selectedCuisines.toList())
    │
    ▼
Vendor Home (refreshes profile)
```

---

## Testing Checklist

- [x] Vendor can access cuisine selection from home
- [x] Grid shows all 20 categories
- [x] Can select up to 5 cuisines
- [x] Cannot select more than 5 (shows snackbar message)
- [x] At least 1 cuisine required to save
- [x] "Save" updates Firestore
- [x] Saved cuisines display on vendor home
- [x] "Clear All" removes all selections
- [x] Selection counter shows correct count
- [x] Selected tiles have visual distinction (orange/checkmark)
- [x] Navigation returns result to vendor home
- [x] Profile refreshes after save

---

## Common Pitfalls Avoided

| Pitfall | Solution |
|---------|----------|
| No limit on selections | Capped at 5 cuisines with snackbar feedback |
| Empty selection allowed | Validation requires at least 1 cuisine |
| Stale data after save | Profile reloaded from Firestore on return |
| Memory leak on async | `if (mounted)` checks before setState |
