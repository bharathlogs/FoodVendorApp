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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Cuisines'),
      ),
      body: Column(
        children: [
          // Instructions
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
          ),

          // Selection count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedCuisines.length} / 5 selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
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
          ),

          // Cuisine grid
          Expanded(
            child: GridView.builder(
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
                        color: isSelected
                            ? Colors.orange
                            : Colors.grey.shade300,
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
            ),
          ),
        ],
      ),

      // Save button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Cuisines'),
          ),
        ),
      ),
    );
  }
}
