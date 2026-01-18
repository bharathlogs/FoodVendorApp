import 'package:flutter/material.dart';

/// Predefined cuisine categories for vendor tagging and filtering
const List<String> cuisineCategories = [
  'South Indian',
  'North Indian',
  'Chinese',
  'Street Food',
  'Biryani',
  'Chaat',
  'Snacks',
  'Beverages',
  'Desserts',
  'Fast Food',
  'Momos',
  'Rolls',
  'Dosa',
  'Idli',
  'Pav Bhaji',
  'Vada Pav',
  'Samosa',
  'Juice',
  'Tea/Coffee',
  'Ice Cream',
];

/// Get icon for cuisine category
IconData getCuisineIcon(String cuisine) {
  switch (cuisine) {
    case 'South Indian':
      return Icons.rice_bowl;
    case 'North Indian':
      return Icons.lunch_dining;
    case 'Chinese':
      return Icons.ramen_dining;
    case 'Street Food':
      return Icons.fastfood;
    case 'Biryani':
      return Icons.rice_bowl;
    case 'Chaat':
      return Icons.tapas;
    case 'Snacks':
      return Icons.cookie;
    case 'Beverages':
      return Icons.local_cafe;
    case 'Desserts':
      return Icons.cake;
    case 'Fast Food':
      return Icons.lunch_dining;
    case 'Momos':
      return Icons.set_meal;
    case 'Rolls':
      return Icons.wrap_text;
    case 'Dosa':
      return Icons.rice_bowl;
    case 'Idli':
      return Icons.breakfast_dining;
    case 'Pav Bhaji':
      return Icons.dinner_dining;
    case 'Vada Pav':
      return Icons.lunch_dining;
    case 'Samosa':
      return Icons.bakery_dining;
    case 'Juice':
      return Icons.local_drink;
    case 'Tea/Coffee':
      return Icons.coffee;
    case 'Ice Cream':
      return Icons.icecream;
    default:
      return Icons.restaurant;
  }
}
