-- =============================================================
-- ABDUL GHAFFAR MEAT SHOP — PostgreSQL Database Schema
-- =============================================================
-- Designed for scalability, data integrity, and performance
-- =============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================
-- ENUMS
-- =============================================================
CREATE TYPE user_role AS ENUM ('customer', 'admin', 'rider', 'superadmin');
CREATE TYPE order_status AS ENUM (
    'pending', 'confirmed', 'preparing', 'cutting', 'packed',
    'rider_assigned', 'out_for_delivery', 'delivered', 'cancelled'
);
CREATE TYPE meat_category AS ENUM ('beef', 'chicken', 'mutton');
CREATE TYPE weight_unit AS ENUM ('kg', 'g');
CREATE TYPE cut_type AS ENUM ('curry_cut', 'bbq_cut', 'boneless', 'mince', 'custom');
CREATE TYPE subscription_status AS ENUM ('active', 'paused', 'cancelled', 'expired');
CREATE TYPE subscription_interval AS ENUM ('weekly', 'biweekly', 'monthly');
CREATE TYPE payment_method AS ENUM ('cod', 'card', 'wallet', 'jazzcash', 'easypaisa');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE day_of_week AS ENUM ('mon','tue','wed','thu','fri','sat','sun');

-- =============================================================
-- USERS & AUTH
-- =============================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone           VARCHAR(15) UNIQUE NOT NULL,
    name            VARCHAR(100),
    email           VARCHAR(255),
    role            user_role NOT NULL DEFAULT 'customer',
    avatar_url      TEXT,
    is_active       BOOLEAN DEFAULT true,
    is_verified     BOOLEAN DEFAULT false,
    fcm_token       TEXT,
    language_pref   VARCHAR(10) DEFAULT 'ur',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);

CREATE TABLE otp_codes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone           VARCHAR(15) NOT NULL,
    otp_code        VARCHAR(6) NOT NULL,
    attempts        SMALLINT DEFAULT 0,
    is_used         BOOLEAN DEFAULT false,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_otp_phone ON otp_codes(phone);
CREATE INDEX idx_otp_lookup ON otp_codes(phone, otp_code) WHERE is_used = false;

-- =============================================================
-- ADDRESSES
-- =============================================================
CREATE TABLE addresses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label           VARCHAR(50) DEFAULT 'Home',
    full_address    TEXT NOT NULL,
    street          VARCHAR(255),
    sector          VARCHAR(100),
    house_no        VARCHAR(50),
    landmark        VARCHAR(255),
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    is_default      BOOLEAN DEFAULT false,
    is_in_service_area BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_addr_user ON addresses(user_id);

-- =============================================================
-- CATEGORIES & PRODUCTS
-- =============================================================
CREATE TABLE categories (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(100) NOT NULL,
    slug            VARCHAR(100) UNIQUE NOT NULL,
    description     TEXT,
    image_url       TEXT,
    sort_order      SMALLINT DEFAULT 0,
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE products (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id     UUID NOT NULL REFERENCES categories(id),
    name            VARCHAR(200) NOT NULL,
    slug            VARCHAR(200) UNIQUE NOT NULL,
    description     TEXT,
    price_per_kg    DECIMAL(10,2) NOT NULL,
    compare_price   DECIMAL(10,2), -- original price for discount display
    stock_kg        DECIMAL(8,2) NOT NULL DEFAULT 0,
    min_order_kg    DECIMAL(4,2) DEFAULT 0.5,
    max_order_kg    DECIMAL(4,2) DEFAULT 5.0,
    images          TEXT[] DEFAULT '{}',
    freshness_status VARCHAR(50) DEFAULT 'Fresh',
    is_featured     BOOLEAN DEFAULT false,
    is_active       BOOLEAN DEFAULT true,
    cut_options     cut_type[] DEFAULT '{curry_cut, bbq_cut, boneless, mince}',
    stock_updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = true;
CREATE INDEX idx_products_featured ON products(is_featured) WHERE is_featured = true;
CREATE INDEX idx_products_stock ON products(stock_kg) WHERE stock_kg > 0;

-- =============================================================
-- FRESHNESS TIMER
-- =============================================================
CREATE TABLE stock_arrivals (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id     UUID NOT NULL REFERENCES categories(id),
    arrival_time    TIME NOT NULL,
    message         VARCHAR(255) NOT NULL,
    is_active       BOOLEAN DEFAULT true,
    day_of_week     day_of_week[], -- NULL means every day
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- CARTS
-- =============================================================
CREATE TABLE carts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    promo_code      VARCHAR(50),
    discount_amount DECIMAL(10,2) DEFAULT 0,
    delivery_notes  TEXT,
    expires_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cart_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id         UUID NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    weight_kg       DECIMAL(5,2) NOT NULL,
    cut_type        cut_type NOT NULL,
    custom_instructions TEXT,
    unit_price      DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);

-- =============================================================
-- ORDERS
-- =============================================================
CREATE TABLE orders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number    VARCHAR(20) UNIQUE NOT NULL,
    user_id         UUID NOT NULL REFERENCES users(id),
    address_id      UUID NOT NULL REFERENCES addresses(id),
    status          order_status NOT NULL DEFAULT 'pending',
    subtotal        DECIMAL(10,2) NOT NULL,
    delivery_fee    DECIMAL(10,2) DEFAULT 0,
    discount        DECIMAL(10,2) DEFAULT 0,
    total           DECIMAL(10,2) NOT NULL,
    payment_method  payment_method DEFAULT 'cod',
    payment_status  payment_status DEFAULT 'pending',
    delivery_notes  TEXT,
    scheduled_date  DATE,
    scheduled_slot  VARCHAR(50), -- e.g. "10:00-11:00"
    is_asap         BOOLEAN DEFAULT true,
    estimated_delivery_at TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ,
    rider_id        UUID REFERENCES users(id),
    preparation_time_min SMALLINT,
    cancellation_reason TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_rider ON orders(rider_id) WHERE rider_id IS NOT NULL;
CREATE INDEX idx_orders_date ON orders(created_at DESC);
CREATE INDEX idx_orders_scheduled ON orders(scheduled_date) WHERE scheduled_date IS NOT NULL;

CREATE TABLE order_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    product_name    VARCHAR(200) NOT NULL, -- snapshot
    weight_kg       DECIMAL(5,2) NOT NULL,
    cut_type        cut_type NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    custom_instructions TEXT
);

CREATE INDEX idx_order_items_order ON order_items(order_id);

CREATE TABLE order_status_log (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    from_status     order_status,
    to_status       order_status NOT NULL,
    changed_by      UUID REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_status_log_order ON order_status_log(order_id);

-- =============================================================
-- REVIEWS
-- =============================================================
CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID UNIQUE NOT NULL REFERENCES orders(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    product_id      UUID NOT NULL REFERENCES products(id),
    rating          SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment         TEXT,
    images          TEXT[] DEFAULT '{}',
    is_approved     BOOLEAN DEFAULT false,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_approved ON reviews(is_approved) WHERE is_approved = true;

-- =============================================================
-- SUBSCRIPTIONS
-- =============================================================
CREATE TABLE subscriptions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id),
    plan_name       VARCHAR(100) NOT NULL,
    description     TEXT,
    interval_type   subscription_interval NOT NULL DEFAULT 'weekly',
    interval_count  SMALLINT DEFAULT 1,
    total_cycles    SMALLINT, -- NULL = ongoing
    cycles_remaining SMALLINT,
    price_per_cycle DECIMAL(10,2) NOT NULL,
    total_price     DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    status          subscription_status DEFAULT 'active',
    next_order_date DATE NOT NULL,
    delivery_slot   VARCHAR(50),
    delivery_notes  TEXT,
    auto_renew      BOOLEAN DEFAULT false,
    address_id      UUID NOT NULL REFERENCES addresses(id),
    start_date      DATE NOT NULL,
    end_date        DATE,
    cancelled_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_subs_user ON subscriptions(user_id);
CREATE INDEX idx_subs_status ON subscriptions(status);
CREATE INDEX idx_subs_next_order ON subscriptions(next_order_date)
    WHERE status = 'active';

CREATE TABLE subscription_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    weight_kg       DECIMAL(5,2) NOT NULL,
    cut_type        cut_type NOT NULL
);

CREATE INDEX idx_subs_items_sub ON subscription_items(subscription_id);

-- =============================================================
-- PROMOTIONS
-- =============================================================
CREATE TABLE promotions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code            VARCHAR(50) UNIQUE NOT NULL,
    description     TEXT,
    discount_type   VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value  DECIMAL(10,2) NOT NULL,
    min_order_amount DECIMAL(10,2) DEFAULT 0,
    max_discount    DECIMAL(10,2),
    max_uses        INTEGER,
    current_uses    INTEGER DEFAULT 0,
    per_user_limit  SMALLINT DEFAULT 1,
    is_active       BOOLEAN DEFAULT true,
    starts_at       TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_promos_active ON promotions(code, is_active)
    WHERE is_active = true AND expires_at > NOW();

CREATE TABLE promo_usage (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promo_id        UUID NOT NULL REFERENCES promotions(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    order_id        UUID REFERENCES orders(id),
    discount_amount DECIMAL(10,2) NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- NOTIFICATIONS
-- =============================================================
CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id),
    title           VARCHAR(200) NOT NULL,
    body            TEXT,
    type            VARCHAR(50), -- order_update, promo, stock_alert, etc.
    ref_id          UUID, -- order_id or other reference
    is_read         BOOLEAN DEFAULT false,
    sent_at         TIMESTAMPTZ DEFAULT NOW(),
    read_at         TIMESTAMPTZ
);

CREATE INDEX idx_notif_user ON notifications(user_id, is_read);

-- =============================================================
-- RIDER MANAGEMENT
-- =============================================================
CREATE TABLE rider_assignments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID UNIQUE NOT NULL REFERENCES orders(id),
    rider_id        UUID NOT NULL REFERENCES users(id),
    assigned_at     TIMESTAMPTZ DEFAULT NOW(),
    accepted_at     TIMESTAMPTZ,
    picked_up_at    TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ,
    notes           TEXT
);

CREATE INDEX idx_rider_assignments_rider ON rider_assignments(rider_id);

-- =============================================================
-- PAYMENTS
-- =============================================================
CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES orders(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    amount          DECIMAL(10,2) NOT NULL,
    method          payment_method NOT NULL,
    status          payment_status NOT NULL DEFAULT 'pending',
    transaction_id  VARCHAR(255),
    gateway_response JSONB,
    paid_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_user ON payments(user_id);

-- =============================================================
-- LOYALTY / REFERRALS (Future)
-- =============================================================
CREATE TABLE loyalty_points (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id),
    points          INTEGER NOT NULL DEFAULT 0,
    lifetime_points INTEGER NOT NULL DEFAULT 0,
    tier            VARCHAR(20) DEFAULT 'bronze', -- bronze, silver, gold
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE referral_codes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID UNIQUE NOT NULL REFERENCES users(id),
    code            VARCHAR(20) UNIQUE NOT NULL,
    total_referrals INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- AUDIT LOG
-- =============================================================
CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID REFERENCES users(id),
    action          VARCHAR(100) NOT NULL,
    entity_type     VARCHAR(50),
    entity_id       UUID,
    old_values      JSONB,
    new_values      JSONB,
    ip_address      INET,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);

-- =============================================================
-- TRIGGERS: updated_at
-- =============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_carts_updated_at
    BEFORE UPDATE ON carts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_subs_updated_at
    BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================
-- SEED DATA
-- =============================================================
INSERT INTO categories (name, slug, description, sort_order) VALUES
    ('Beef', 'beef', 'Fresh halal beef — premium cuts for every dish', 1),
    ('Chicken', 'chicken', 'Farm-fresh chicken, cleaned and ready to cook', 2),
    ('Mutton', 'mutton', 'Tender mutton from quality livestock', 3);

INSERT INTO stock_arrivals (category_id, arrival_time, message) VALUES
    ((SELECT id FROM categories WHERE slug = 'chicken'), '07:00', 'Fresh Chicken Arrived at 7:00 AM'),
    ((SELECT id FROM categories WHERE slug = 'beef'), '06:30', 'Fresh Beef Available Since 6:30 AM'),
    ((SELECT id FROM categories WHERE slug = 'mutton'), '08:00', 'Fresh Mutton Available Today');
