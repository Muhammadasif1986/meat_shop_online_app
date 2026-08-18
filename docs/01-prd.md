# Product Requirements Document — Abdul Ghaffar Meat Shop

## 1. Executive Summary

**Abdul Ghaffar Meat Shop** is a digital meat delivery platform serving Naval Colony, Karachi. The platform enables customers to order fresh beef, chicken, and mutton online with delivery within 20-30 minutes. It provides a complete ordering lifecycle from product discovery through subscription management.

## 2. Problem Statement

Residents of Naval Colony face:
- No reliable online meat delivery service
- Inconsistent meat quality and freshness
- Long wait times at traditional shops
- No visibility into stock availability
- No scheduling or subscription options

## 3. Solution

A unified platform offering:
- Real-time meat catalog with live freshness indicators
- Smart ordering with weight/cut customization
- 20-30 minute delivery within service area
- Subscription plans for weekly/monthly needs
- Real-time order tracking from preparation to delivery

## 4. Target Users

### Primary: Residents of Naval Colony
- Age: 25-55
- Family-oriented, value quality and convenience
- Comfortable with Urdu and English
- Smartphone users (Android majority)

### Secondary: Nearby societies
- Same demographics as primary
- Slightly longer delivery times

### Internal: Shop Staff
- Butchers/cutters preparing orders
- Riders delivering orders

## 5. User Personas

**Ahmed (35) — Father of 3**
- Orders meat 2-3 times weekly
- Needs reliable quality and timely delivery
- Wants subscription for weekly chicken

**Fatima (28) — Working Professional**
- Orders after work, needs ASAP delivery
- Prefers pre-cut meat packs
- Uses app for promotions and offers

**Butcher (Admin)** — Manages inventory, order prep
**Rider** — Delivers orders, updates status

## 6. Functional Requirements

### FR1: User Registration & Auth
- Phone number input with country code
- OTP sent via SMS (Twilio/Firebase Auth)
- JWT token on successful verification
- Profile: name, phone, default address
- Multiple saved addresses
- Guest browsing (cart requires login)

### FR2: Product Catalog
- Categories: Beef, Chicken, Mutton
- Subcategories: Premium, Regular, Organic (future)
- Product fields: name, images(3), price/KG, stock, freshness, description, cutOptions
- Search by name/category
- Filter by: category, price range, availability
- Sort by: popularity, price, freshness

### FR3: Smart Ordering
- Weight selection: 500g, 1kg, 2kg, custom (200g-5kg in 100g steps)
- Cut types: Curry Cut, BBQ Cut, Boneless, Mince/Qeema
- Custom instructions text field
- Real-time price calculation
- Minimum order amount: Rs. 500

### FR4: Cart & Checkout
- Persistent cart (saved between sessions)
- In-cart editing of weight/cut/quantity
- Delivery notes field
- Order summary with itemized pricing
- Promo code field
- Delivery fee calculation
- Total with all charges

### FR5: Delivery Scheduling
- "ASAP" mode (deliver within 30 min)
- Schedule mode: select date and 1-hour time slot
- Available slots: 8:00 AM — 10:00 PM
- Cutoff for same-day: 9:00 PM (orders after go to next day)

### FR6: Order Tracking
- Real-time status updates
- Push notifications on status change
- Estimated delivery time display
- Rider details (name, phone) once assigned

### FR7: Reviews
- 1-5 star rating
- Written review (optional)
- Photo upload (optional)
- Only allowed after delivery
- One review per order

### FR8: Reorder
- One-tap reorder from order history
- Same items, weights, cuts
- New checkout flow (can modify before placing)

### FR9: Notifications
- Order status updates (mandatory)
- Promotional offers (opt-in)
- Fresh stock alerts (opt-in)
- Birthday/special offers (opt-in)
- FCM integration

### FR10: Fresh Stock Timer
- Daily stock arrival times displayed
- "Fresh Chicken Arrived at 7:00 AM"
- "Today's Mutton: Fresh & Ready"
- Countdown to next stock arrival

### FR11: Society-Exclusive Delivery
- Geofenced delivery area
- Free delivery above Rs. 1000
- Delivery fee: Rs. 50 for orders below Rs. 1000
- Service area validation at address entry

### FR12: Subscription Plans
- **Weekly Chicken**: 2kg chicken/week, 4 weeks
- **Weekly Beef**: 2kg beef/week, 4 weeks
- **Weekly Mutton**: 1kg mutton/week, 4 weeks  
- **Family Mixed**: 3kg mixed meat/week, 4 weeks
- Auto-generated orders every week
- Pause/cancel anytime
- Discount: 10% on monthly subscriptions

## 7. Non-Functional Requirements

- **Performance**: API response < 200ms P95, page load < 2s
- **Availability**: 99.9% uptime during business hours (8AM-11PM)
- **Security**: End-to-end encryption, JWT with 1hr expiry, rate limiting
- **Scalability**: Support 1000 concurrent users at launch, 10x growth target
- **Offline**: App should gracefully handle network loss, cache catalog
- **Accessibility**: Urdu language support, large text option
- **Compliance**: Data privacy (Pakistan's PECA 2016), payment security

## 8. MVP Scope

### Phase 1 — Core Ordering (Week 1-6)
- Phone auth + OTP
- Product catalog (Beef, Chicken, Mutton)
- Cart with weight/cut options
- Checkout with delivery scheduling
- Order tracking (manual status updates)
- Admin order management
- Basic analytics

### Phase 2 — Enhanced Features (Week 7-10)
- Reviews & ratings
- Reorder feature
- Push notifications
- Subscription plans
- Promotions & discount codes
- Advanced analytics

### Phase 3 — Scale (Week 11-14)
- Rider app/module
- Live tracking
- WhatsApp ordering
- Loyalty points
- Referral program

## 9. Success Metrics

| Metric | Target |
|--------|--------|
| Daily Active Users (DAU) | 100 (Month 1) |
| Order Conversion Rate | > 25% |
| Avg Order Value | Rs. 1,500 |
| Delivery Time | < 30 min (85% orders) |
| Customer Retention (30d) | > 40% |
| App Rating | > 4.5 |
| Order Accuracy | > 99% |
