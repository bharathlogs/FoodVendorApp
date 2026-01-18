import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import 'vendor_list_screen.dart';
import 'map_screen.dart';
import 'favorites_screen.dart';

class CustomerHome extends ConsumerStatefulWidget {
  const CustomerHome({super.key});

  @override
  ConsumerState<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends ConsumerState<CustomerHome> {
  int _currentIndex = 0;

  String get _title {
    switch (_currentIndex) {
      case 0:
        return 'Find Food Vendors';
      case 1:
        return 'Nearby Vendors';
      case 2:
        return 'Favorites';
      default:
        return 'Food Finder';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          VendorListScreen(),
          MapScreen(),
          FavoritesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list),
            selectedIcon: Icon(Icons.list_alt),
            label: 'List',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
