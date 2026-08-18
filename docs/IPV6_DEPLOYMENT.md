# IPv6 Production Deployment Guide
## Abdul Ghaffar Meat Shop — AGMS

### Problem
Supabase PostgreSQL uses **IPv6-only** hostnames (AAAA records). WSL2 and many home/VPS networks lack IPv6 routing, making direct connection impossible.

### Solution Options

#### Option A: IPv6-capable VPS (Recommended)
Deploy backend + admin on a VPS with native IPv6 support:

| Provider | IPv6 | Cost | Notes |
|----------|------|------|-------|
| **Hetzner Cloud** | ✅ Full /64 subnet | €4–€8/mo | Best value, native IPv6 |
| **Linode** | ✅ /64 subnet | $12/mo | Good docs |
| **DigitalOcean** | ✅ /124 subnet | $12/mo | Simple setup |
| **AWS EC2** | ✅ | ~$8/mo (t4g.nano) | Free tier eligible |

**Setup Steps:**
```bash
# 1. Provision a VPS (Ubuntu 22.04/24.04)
# 2. Configure IPv6:
cat >> /etc/netplan/01-netcfg.yaml << 'EOF'
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      dhcp6: true
      accept-ra: true
EOF
netplan apply

# 3. Verify IPv6:
ping6 -c 3 db.${SUPABASE_REF}.pool.supabase.com

# 4. Deploy with docker-compose (see docker-compose.production.yml)
```

**Environment (.env.production):**
```bash
DATABASE_URL=postgresql+asyncpg://postgres:${DB_PASS}@db.${SUPABASE_REF}.pool.supabase.com:5432/postgres
# No PGBouncer — use direct port 5432 for asyncpg
```

#### Option B: Cloudflare Tunnel (No IPv6 Needed)
Use Cloudflare Tunnel to bridge your VPS → Supabase without IPv6:

```bash
# Install cloudflared on VPS
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Authenticate
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create agms-supabase

# Configure DNS
cloudflared tunnel route dns agms-supabase db.agms.internal

# Run tunnel (private network mode)
cloudflared tunnel run agms-supabase
```

Then set `DATABASE_URL` to use the tunneled endpoint.

#### Option C: Supabase MCP (Development Only)
For local dev, continue using Supabase MCP (HTTPS-based) which works over IPv4.

### Firewall Rules
```bash
# Allow only your app servers
ufw allow from ${VPS_IP} to any port 5432 proto tcp
ufw deny 5432
```

### Monitoring
```bash
# Check Supabase connection pool
SELECT * FROM pg_stat_activity WHERE datname = 'postgres';
# Connection count
SELECT count(*) FROM pg_stat_activity;
```
