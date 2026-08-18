# UI Specifications & User Flows — Abdul Ghaffar Meat Shop

## 1. USER FLOW DIAGRAMS

### A. Onboarding & Auth Flow

```
App Launch
    │
    ├──► Splash Screen (2s)
    │       │
    │       ├──► [Has Token] → Home Screen
    │       └──► [No Token] → Welcome Screen
    │
    ▼
Welcome Screen
    │
    ├──► "Login with Phone"
    │       │
    │       ▼
    │   Phone Input Screen
    │   [+92 ___ _______]  [Send OTP]
    │       │
    │       ▼
    │   OTP Verification Screen
    │   [____ ____ ____ ____] (6-digit)
    │   [Resend in 30s]
    │       │
    │       ▼
    │   Registration (if new user)
    │   [Your Name]
    │   [Your Email (optional)]
    │   [Save & Continue]
    │       │
    │       ▼
    │   Home Screen
    │
    └──► "Browse as Guest"
            │
            ▼
        Home Screen (limited - no ordering)
```

### B. Order Placement Flow

```
Home Screen
    │
    ├──► Browse Categories → Product Grid → Product Detail
    │       │                      │                  │
    │       │                      │           [Select Weight]
    │       │                      │           [Select Cut Type]
    │       │                      │           [Add to Cart]
    │       │                      │                  │
    │       │                      └──────────────────┘
    │       │
    │       ▼
    │   Cart Screen
    │   [Item List with edit/remove]
    │   [Delivery Notes]
    │   [Promo Code]
    │   [Order Summary]
    │   [Proceed to Checkout]
    │       │
    │       ▼
    │   Delivery Screen
    │   [Select Address / Add New]
    │   [ASAP / Schedule]
    │   [Time Slot Picker (if scheduled)]
    │   [Payment Method]
    │   [Place Order]
    │       │
    │       ▼
    │   Order Confirmation
    │   [Order #12345]
    │   [Estimated Delivery: 20 min]
    │   [Track Order]
    │   [Back to Home]
```

### C. Order Tracking Flow

```
Order Screen
    │
    └──► Active Order Card → Track Order Screen
                │
                ▼
        Timeline View
        ┌──────────────────────┐
        │ ✓ Order Received     │ ◄── Green check
        │ ✓ Confirmed          │
        │ ○ Preparing          │ ◄── Current step (animated)
        │ ○ Cutting Meat       │
        │ ○ Packed             │
        │ ○ Rider Assigned     │
        │ ○ Out for Delivery   │
        │ ○ Delivered          │
        └──────────────────────┘
                │
        [Rider Info Card] (when assigned)
        ┌──────────────────────┐
        │ Rider: Ali           │
        │ Phone: 0300...       │
        │ [Call Rider]         │
        └──────────────────────┘
```

### D. Subscription Flow

```
Profile → My Subscriptions → Create Subscription
    │
    ├──► Select Plan Type
    │   [Weekly Chicken - Rs. 2,000]
    │   [Weekly Beef - Rs. 3,000]
    │   [Family Mixed - Rs. 5,000]
    │
    ├──► Customize
    │   [Select Products & Weights]
    │   [Delivery Day: Saturday]
    │   [Delivery Slot: 10-11 AM]
    │
    ├──► Payment
    │   [Total: Rs. 8,000/month]
    │   [10% Discount Applied]
    │
    └──► Confirmation
        [Active Subscription Card]
        [Next Delivery: June 20, 2026]
        [Pause / Cancel Options]
```

## 2. SCREEN-BY-SCREEN UI SPECIFICATIONS

### Screen 1: Splash Screen
- Brand logo centered (meat shop branding)
- Background: deep red (#8B0000) or dark warm tone
- Tagline: "Fresh Meat, Delivered Fast"
- Auto-navigate after 2 seconds

### Screen 2: Welcome Screen
- Hero image: high-quality meat platter
- Title: "Abdul Ghaffar Meat Shop"
- Subtitle: "Fresh Halal Meat — Naval Colony"
- Two CTA buttons:
  - Primary: "Login with Phone" (filled, white text on red)
  - Secondary: "Browse as Guest" (outlined)
- Trust badges: "Hygienic | Fresh | Fast Delivery"

### Screen 3: Phone Input
- Country code picker (+92 default)
- Phone number input (10 digits)
- "Send OTP" button (disabled until 10 digits)
- Terms & Privacy policy links

### Screen 4: OTP Verification
- 6 digit input boxes (auto-advance)
- Timer countdown: "Resend code in 30s"
- "Verify" button
- Auto-verify option on supported devices

### Screen 5: Home Screen (Main Tab)
- **Header**: Logo + Location badge ("Naval Colony") + Notification bell
- **Fresh Stock Banner**: Animated banner showing today's arrival times
- **Category Cards**: Beef, Chicken, Mutton (horizontal scroll, image + name)
- **Featured Products**: Product grid (2 columns), card shows image, name, price/kg
- **Quick Order Section**: Most popular items
- **Bottom Nav**: Home | Categories | Orders | Profile

### Screen 6: Product Detail
- Full-width image gallery (swipeable)
- Product name + price per KG
- Freshness badge: "Fresh Today" green badge
- Stock indicator: "In Stock" / "Only X kg left"
- Weight selector: 500g | 1kg | 2kg | Custom slider
- Cut type selector: Button group (Curry Cut, BBQ, Boneless, Mince)
- Custom instructions text field
- Price summary: "Total: Rs. 850"
- "Add to Cart" button (bottom fixed)
- Reviews section below fold

### Screen 7: Cart Screen
- List of cart items with:
  - Product thumbnail + name
  - Weight + cut type
  - Quantity stepper
  - Remove button (swipe or tap)
  - Item subtotal
- Delivery notes text field
- Promo code input + "Apply" button
- Order summary card:
  - Subtotal
  - Delivery fee
  - Discount
  - **Total**
- "Proceed to Checkout" button

### Screen 8: Checkout - Delivery
- **Address Section**:
  - Saved addresses list (radio select)
  - "Add New Address" button
  - Address form: label, house/street, sector, landmark
- **Delivery Section**:
  - Toggle: ASAP / Schedule
  - Time slot picker (if scheduled)
- **Payment Section**:
  - COD (Cash on Delivery) — default
  - JazzCash / EasyPaisa (future)
- **Order Summary** (collapsible)
- "Place Order" button (with total amount)

### Screen 9: Order Confirmation
- Success animation (checkmark)
- Order number prominently displayed
- Estimated delivery time
- "Track Order" button
- "Continue Shopping" link
- Order summary

### Screen 10: Track Order
- Status timeline (vertical stepper)
- Current step highlighted with animation
- Estimated delivery countdown timer
- Rider info card (when assigned)
- "Call Support" button
- "Cancel Order" link (only if allowed)

### Screen 11: Orders Tab
- **Active Orders** section (carousel for multiple)
- **Past Orders** section (list, paginated)
- Each order card shows:
  - Order number
  - Status badge (colored)
  - Item count
  - Total amount
  - Date
  - "Track" / "Reorder" / "Rate" buttons

### Screen 12: Profile Screen
- Avatar + name + phone
- **Menu items**:
  - My Addresses
  - My Subscriptions
  - Order History
  - Notifications
  - Reviews & Ratings
  - Language (English/Urdu)
  - About Us
  - Logout

### Screen 13: Subscription Management
- Active subscription cards
  - Plan name
  - Next delivery date
  - Status badge
  - Pause/Resume/Cancel buttons
- "Create New Subscription" CTA
- Subscription history

### Screen 14: Subscription Creation
- Plan selection cards
- Product & weight configuration per delivery
- Delivery day & time selection
- Duration picker (4 weeks / 8 weeks / 12 weeks)
- Price summary with discount
- Confirm button

### Screen 15: Review Screen
- Order number header
- Star rating (tap-to-rate, 5 stars)
- "Write a review" text area
- Add photos option (up to 3)
- Submit button

## 3. ADMIN DASHBOARD SCREENS

### Screen A: Admin Login
- Email + password login
- "Forgot Password" link

### Screen B: Dashboard Home
- **Stats Cards**: Today's Orders, Revenue, Customers, Pending Orders
- **Chart**: Daily sales (last 7 days)
- **Recent Orders Table** (last 10)
- **Low Stock Alerts** notification bar

### Screen C: Orders Management
- Filters: Status, Date range, Customer search
- Table: Order #, Customer, Items, Total, Status, Date, Actions
- Row click → Order detail modal/page
- Order detail: items, status timeline, customer info, action buttons
- Status change dropdown + "Assign Rider" dialog

### Screen D: Products Management
- Product list with search & filters
- Add Product form (modal/page)
  - Name, Category, Price, Stock, Images
  - Cut options checkboxes
  - Active toggle
- Edit/Delete actions per product

### Screen E: Customers
- Customer table: Name, Phone, Orders, Total Spent, Joined Date
- Click → Customer detail with order history

### Screen F: Analytics
- Date range picker
- Line chart: Revenue over time
- Pie chart: Orders by category
- Bar chart: Top selling products
- Table: Monthly summary
- Export CSV button

### Screen G: Promotions
- Active promotions table
- Create promo form: Code, Discount type/value, Min order, Max uses, Expiry
- Usage tracking per promo

## 4. DESIGN SYSTEM

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| `--color-primary` | #8B0000 | Brand red, CTA buttons |
| `--color-primary-dark` | #5C0000 | Header, footer |
| `--color-secondary` | #FF6B35 | Accents, badges |
| `--color-success` | #2ECC71 | Freshness, delivered |
| `--color-warning` | #F39C12 | Preparing, pending |
| `--color-bg` | #FAFAFA | Page background |
| `--color-surface` | #FFFFFF | Cards, modals |
| `--color-text` | #1A1A1A | Primary text |
| `--color-text-secondary` | #666666 | Secondary text |

### Typography
| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `h1` | 28px | Bold | Page titles |
| `h2` | 22px | Bold | Section headers |
| `h3` | 18px | Semi-bold | Card titles |
| `body` | 16px | Regular | Body text |
| `body-sm` | 14px | Regular | Metadata |
| `caption` | 12px | Regular | Badges, timestamps |

### Spacing
- Base unit: 8px
- Padding: 16px (mobile), 24px (desktop/tablet)
- Border radius: 12px (cards), 8px (buttons), 20px (pills)

### Iconography
- Material Icons (Flutter)
- Lucide Icons (Next.js admin)
- Custom meat-related icons where needed

### Dark Mode
- Respect system preference
- Dark background: #121212
- Surface: #1E1E1E
- Preserved brand colors with adjusted contrast
