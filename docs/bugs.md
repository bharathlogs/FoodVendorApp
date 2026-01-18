# Bug Tracking

## Critical (Must Fix Before Launch)
| ID | Description | Status | Fix Notes |
|----|-------------|--------|-----------|
| C1 | Map tiles wrong userAgentPackageName | FIXED | Changed from placeholder to com.vendorapp.food_vendor_app |

## High Priority
| ID | Description | Status | Fix Notes |
|----|-------------|--------|-----------|
| H1 | setState after dispose in MapScreen | FIXED | Added mounted checks in _initCustomerLocation async callback |

## Medium Priority
| ID | Description | Status | Fix Notes |
|----|-------------|--------|-----------|
| M1 | No centralized error handling | FIXED | Created ErrorHandler utility with user-friendly messages |

## Low Priority (Nice to Have)
| ID | Description | Status | Fix Notes |
|----|-------------|--------|-----------|
| L1 | | | |

## Won't Fix (Known Limitations)
| ID | Description | Reason |
|----|-------------|--------|
| W1 | Background location may stop on some OEMs | Android OEM-specific battery optimization beyond app control |
