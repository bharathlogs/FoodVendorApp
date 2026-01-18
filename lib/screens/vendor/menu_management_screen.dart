import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/vendor/menu_item_form.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  String? get _vendorId => _authService.currentUser?.uid;

  void _showAddItemForm(int currentItemCount) {
    if (_vendorId == null) return;

    // Check limit before showing form
    if (currentItemCount >= DatabaseService.maxMenuItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Menu limit reached (${DatabaseService.maxMenuItems} items maximum)',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => MenuItemForm(
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => MenuItemForm(
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

  Future<void> _addMenuItem(
    String name,
    double price,
    String? description,
  ) async {
    if (_vendorId == null) return;

    try {
      final newItem = MenuItem(
        itemId: '', // Will be assigned by Firestore
        name: name,
        price: price,
        description: description,
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      await _databaseService.addMenuItem(_vendorId!, newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "$name" to menu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated "$name"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }

  Future<void> _deleteMenuItem(String itemId, String itemName) async {
    if (_vendorId == null) return;

    try {
      await _databaseService.deleteMenuItem(_vendorId!, itemId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "$itemName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  Future<void> _toggleItemAvailability(MenuItem item) async {
    if (_vendorId == null) return;

    try {
      await _databaseService.updateMenuItem(_vendorId!, item.itemId, {
        'isAvailable': !item.isAvailable,
      });

      if (mounted) {
        final status = !item.isAvailable ? 'available' : 'unavailable';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${item.name}" marked as $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vendorId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return StreamBuilder<List<MenuItem>>(
      stream: _databaseService.getMenuItemsStream(_vendorId!),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final itemCount = items.length;
        final isAtLimit = itemCount >= DatabaseService.maxMenuItems;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Menu'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(24),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$itemCount / ${DatabaseService.maxMenuItems} items',
                  style: TextStyle(
                    fontSize: 13,
                    color: isAtLimit ? Colors.red.shade300 : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          body: _buildBody(snapshot, items),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddItemForm(itemCount),
            icon: const Icon(Icons.add),
            label: Text(isAtLimit ? 'Limit Reached' : 'Add Item'),
            backgroundColor: isAtLimit ? Colors.grey : Colors.orange,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<List<MenuItem>> snapshot, List<MenuItem> items) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Text('Error: ${snapshot.error}'),
      );
    }

    if (items.isEmpty) {
      return _buildEmptyState(0);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildEmptyState(int currentItemCount) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No menu items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your menu so\ncustomers know what you sell',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddItemForm(currentItemCount),
            icon: const Icon(Icons.add),
            label: const Text('Add First Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditItemForm(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Availability indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isAvailable ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: item.isAvailable
                            ? null
                            : TextDecoration.lineThrough,
                        color: item.isAvailable ? null : Colors.grey,
                      ),
                    ),
                    if (item.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Price
              Text(
                'Rs ${item.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: item.isAvailable ? Colors.green.shade700 : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),

              // Availability toggle
              Switch(
                value: item.isAvailable,
                onChanged: (_) => _toggleItemAvailability(item),
                activeTrackColor: Colors.green.shade200,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
