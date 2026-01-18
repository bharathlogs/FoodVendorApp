# UI Polish Checklist

## Vendor Screens

### Vendor Dashboard (vendor_home.dart)
- [x] Loading indicators shown during async operations
- [x] Error messages clear and actionable
- [x] Success messages (SnackBars) shown appropriately
- [x] Disabled states (grey) for unavailable actions
- [x] Consistent padding and spacing
- [x] Status transitions show loading indicator

### Menu Management (menu_management_screen.dart)
- [x] Loading indicator during item operations
- [x] Forms validate before submission
- [x] Empty state has helpful message
- [x] Item count displayed (X / 50 items)
- [x] Unavailable items visually distinct (strikethrough/grey)

### Cuisine Selection (cuisine_selection_screen.dart)
- [x] Save button disabled when no changes
- [x] Loading indicator during save
- [x] Clear all button available
- [x] Selected cuisines visually highlighted

## Customer Screens

### Map Screen (map_screen.dart)
- [x] Map loads smoothly
- [x] Markers are clearly visible (orange for vendors, blue for customer)
- [x] Bottom sheet doesn't overlap important content
- [x] Filter chips scroll smoothly
- [x] Empty states have helpful messages
- [x] Location error shows retry button
- [x] Loading indicator while getting location

### Vendor Detail Screen (vendor_detail_screen.dart)
- [x] Vendor info card displays correctly
- [x] Menu items show prices
- [x] Distance displayed when available
- [x] Cuisine tags displayed

### Vendor Bottom Sheet (vendor_bottom_sheet.dart)
- [x] Shows vendor name and status
- [x] Shows distance and walking time
- [x] Shows cuisine tags
- [x] View Menu button prominent

## Auth Screens

### Login Screen (login_screen.dart)
- [x] Form validates before submission
- [x] Loading indicator during login
- [x] Error messages displayed clearly
- [x] Guest option available

### Signup Screen (signup_screen.dart)
- [x] Form validates before submission
- [x] Loading indicator during signup
- [x] Role selection clear (Customer/Vendor)
- [x] Dynamic label for name field based on role

## General

- [x] App bar titles consistent
- [x] Colors consistent (orange for primary actions)
- [x] Font sizes readable
- [x] Touch targets large enough (48dp minimum for buttons)
- [x] No text overflow/clipping (ellipsis used where needed)
- [x] Proper keyboard handling (SingleChildScrollView on forms)
- [x] Mounted checks before setState in async callbacks

## Accessibility

- [ ] Screen reader labels on interactive elements
- [ ] Sufficient color contrast
- [ ] Focus order logical

## Performance

- [x] Streams used for real-time updates (snapshots())
- [x] Location updates efficient (interval-based)
- [x] Location queue limits to 100 entries
- [x] Null checks prevent crashes
