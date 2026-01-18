import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../models/menu_item.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  static const int _maxMenuItems = 50;

  String? get _vendorId => _authService.currentUser?.uid;

  void _showAddItemForm(int currentItemCount) {
    if (_vendorId == null) return;

    if (currentItemCount >= _maxMenuItems) {
      _showLimitReachedDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModernMenuItemForm(
        onSave: (name, price, description) async {
          Navigator.pop(context);
          await _addMenuItem(name, price, description);
        },
      ),
    );
  }

  void _showEditItemForm(MenuItem item) {
    if (_vendorId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModernMenuItemForm(
        existingItem: item,
        onSave: (name, price, description) async {
          Navigator.pop(context);
          await _updateMenuItem(item.itemId, name, price, description);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteMenuItem(item.itemId, item.name);
        },
      ),
    );
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            const Text('Menu Full'),
          ],
        ),
        content: const Text(
          'You\'ve reached the maximum of 50 menu items. Delete some items to add new ones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMenuItem(String name, double price, String? description) async {
    if (_vendorId == null) return;

    try {
      final newItem = MenuItem(
        itemId: '',
        name: name,
        price: price,
        description: description,
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      await _databaseService.addMenuItem(_vendorId!, newItem);

      if (mounted) {
        _showSuccessSnackBar('Added "$name" to menu');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error adding item: $e');
      }
    }
  }

  Future<void> _updateMenuItem(
    String itemId,
    String name,
    double price,
    String? description,
  ) async {
    if (_vendorId == null) return;

    try {
      await _databaseService.updateMenuItem(_vendorId!, itemId, {
        'name': name,
        'price': price,
        'description': description,
      });

      if (mounted) {
        _showSuccessSnackBar('Updated "$name"');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating item: $e');
      }
    }
  }

  Future<void> _deleteMenuItem(String itemId, String itemName) async {
    if (_vendorId == null) return;

    try {
      await _databaseService.deleteMenuItem(_vendorId!, itemId);

      if (mounted) {
        _showSuccessSnackBar('Deleted "$itemName"');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error deleting item: $e');
      }
    }
  }

  Future<void> _toggleItemAvailability(MenuItem item) async {
    if (_vendorId == null) return;

    try {
      await _databaseService.updateMenuItem(_vendorId!, item.itemId, {
        'isAvailable': !item.isAvailable,
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating item: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_vendorId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          StreamBuilder<List<MenuItem>>(
            stream: _databaseService.getMenuItemsStream(_vendorId!),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: count >= _maxMenuItems
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count/$_maxMenuItems',
                    style: TextStyle(
                      color: count >= _maxMenuItems
                          ? AppColors.error
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<MenuItem>>(
        stream: _databaseService.getMenuItemsStream(_vendorId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerList(itemCount: 5, itemHeight: 100);
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildMenuItemCard(item);
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<MenuItem>>(
        stream: _databaseService.getMenuItemsStream(_vendorId!),
        builder: (context, snapshot) {
          final itemCount = snapshot.data?.length ?? 0;
          final isAtLimit = itemCount >= _maxMenuItems;

          return FloatingActionButton.extended(
            onPressed: () => _showAddItemForm(itemCount),
            backgroundColor: isAtLimit ? Colors.grey : AppColors.primary,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No menu items yet',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your menu to let\ncustomers know what you offer',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Add Your First Item',
              icon: Icons.add,
              expanded: false,
              onPressed: () => _showAddItemForm(0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showEditItemForm(item),
      child: Row(
        children: [
          // Food Icon with availability indicator
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: item.isAvailable
                      ? AppColors.primaryLight
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fastfood,
                  color: item.isAvailable
                      ? AppColors.primary
                      : Colors.grey,
                  size: 28,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.isAvailable ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.labelLarge.copyWith(
                    decoration: item.isAvailable
                        ? null
                        : TextDecoration.lineThrough,
                    color: item.isAvailable
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: AppTextStyles.priceSmall.copyWith(
                    color: item.isAvailable
                        ? AppColors.success
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          // Availability toggle
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: item.isAvailable,
              onChanged: (_) => _toggleItemAvailability(item),
              activeThumbColor: AppColors.success,
              activeTrackColor: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Menu Item Form
class _ModernMenuItemForm extends StatefulWidget {
  final MenuItem? existingItem;
  final Function(String name, double price, String? description) onSave;
  final VoidCallback? onDelete;

  const _ModernMenuItemForm({
    this.existingItem,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_ModernMenuItemForm> createState() => _ModernMenuItemFormState();
}

class _ModernMenuItemFormState extends State<_ModernMenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingItem?.name ?? '',
    );
    _priceController = TextEditingController(
      text: widget.existingItem?.price.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingItem?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final description = _descriptionController.text.trim();

    widget.onSave(
      name,
      price,
      description.isNotEmpty ? description : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Text(
                isEditing ? 'Edit Item' : 'Add New Item',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 24),

              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Masala Dosa',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: '50',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of the item',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
                maxLength: 150,
              ),
              const SizedBox(height: 24),

              // Buttons
              PrimaryButton(
                text: isEditing ? 'Update Item' : 'Add Item',
                isLoading: _isSaving,
                onPressed: _save,
              ),

              if (isEditing && widget.onDelete != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('Delete Item?'),
                          content: Text(
                            'Are you sure you want to delete "${widget.existingItem!.name}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onDelete!();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Delete Item'),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
