#!/bin/bash
# Carchip Backend - Ubuntu VPS Deployment Script
# Usage: sudo bash deploy.sh

set -euo pipefail

# ─── Configuration ─────────────────────────────────────────────────────────────
APP_DIR="/opt/carchip"
DOMAIN="api.carchip.com"
REPO_URL="${REPO_URL:-}" # Set via environment or prompt

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}══════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════════════${NC}\n"; }

# ─── Check Root ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (sudo bash deploy.sh)"
   exit 1
fi

log_section "Carchip Backend Deployment"

# ─── Step 1: System Update ─────────────────────────────────────────────────────
log_section "Step 1: System Update"
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
    curl \
    wget \
    git \
    ufw \
    certbot \
    python3-certbot-nginx \
    openssl

log_info "System packages updated"

# ─── Step 2: Install Docker ────────────────────────────────────────────────────
log_section "Step 2: Installing Docker"

if command -v docker &>/dev/null; then
    log_warn "Docker already installed: $(docker --version)"
else
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
    systemctl enable docker
    systemctl start docker
    log_info "Docker installed: $(docker --version)"
fi

# ─── Step 3: Install Docker Compose ───────────────────────────────────────────
log_section "Step 3: Installing Docker Compose"

if command -v docker compose &>/dev/null; then
    log_warn "Docker Compose already available"
else
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log_info "Docker Compose installed: $(docker-compose --version)"
fi

# ─── Step 4: Clone Repository ──────────────────────────────────────────────────
log_section "Step 4: Setting Up Application"

if [ -z "$REPO_URL" ]; then
    read -p "Enter your Git repository URL: " REPO_URL
fi

if [ -d "$APP_DIR" ]; then
    log_warn "App directory exists. Pulling latest changes..."
    cd "$APP_DIR"
    git pull origin main
else
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
    log_info "Repository cloned to $APP_DIR"
fi

# Navigate to backend directory
if [ -d "$APP_DIR/backend" ]; then
    BACKEND_DIR="$APP_DIR/backend"
else
    BACKEND_DIR="$APP_DIR"
fi

cd "$BACKEND_DIR"

# ─── Step 5: Environment Setup ─────────────────────────────────────────────────
log_section "Step 5: Environment Configuration"

if [ ! -f "$BACKEND_DIR/.env" ]; then
    if [ -f "$BACKEND_DIR/.env.example" ]; then
        cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
        log_warn ".env created from .env.example"
        log_warn "IMPORTANT: Edit $BACKEND_DIR/.env with your production values before proceeding!"
        echo ""
        echo "Required environment variables to set:"
        echo "  - JWT_SECRET (min 32 chars)"
        echo "  - JWT_REFRESH_SECRET (min 32 chars)"
        echo "  - WHATSGPS_API_KEY"
        echo "  - WHATSGPS_USERNAME"
        echo "  - WHATSGPS_PASSWORD"
        echo "  - FCM_PROJECT_ID"
        echo "  - FCM_PRIVATE_KEY"
        echo "  - FCM_CLIENT_EMAIL"
        echo "  - POSTGRES_PASSWORD"
        echo ""
        read -p "Press Enter after you have configured .env to continue..." _
    else
        log_error ".env.example not found. Cannot create .env file."
        exit 1
    fi
else
    log_info ".env file already exists"
fi

# Generate secure JWT secrets if placeholders detected
source "$BACKEND_DIR/.env"
if [[ "${JWT_SECRET:-}" == *"change-in-production"* ]] || [ -z "${JWT_SECRET:-}" ]; then
    NEW_JWT_SECRET=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-64)
    NEW_REFRESH_SECRET=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-64)
    sed -i "s|JWT_SECRET=.*|JWT_SECRET=${NEW_JWT_SECRET}|g" "$BACKEND_DIR/.env"
    sed -i "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=${NEW_REFRESH_SECRET}|g" "$BACKEND_DIR/.env"
    log_info "Generated new JWT secrets"
fi

# ─── Step 6: Firewall Setup ────────────────────────────────────────────────────
log_section "Step 6: Firewall Configuration"

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
log_info "UFW firewall configured"

# ─── Step 7: SSL Certificate Generation (Self-Signed for now) ──────────────────
log_section "Step 7: SSL Setup"

NGINX_CERTS_DIR="$BACKEND_DIR/nginx/certs"
mkdir -p "$NGINX_CERTS_DIR"

if [ ! -f "$NGINX_CERTS_DIR/selfsigned.crt" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$NGINX_CERTS_DIR/selfsigned.key" \
        -out "$NGINX_CERTS_DIR/selfsigned.crt" \
        -subj "/C=US/ST=State/L=City/O=Carchip/CN=$DOMAIN" 2>/dev/null
    log_info "Self-signed SSL certificate generated"
fi

# ─── Step 8: Build & Start Containers ─────────────────────────────────────────
log_section "Step 8: Starting Docker Containers"

cd "$BACKEND_DIR"

# Pull latest images
docker-compose pull postgres redis nginx 2>/dev/null || true

# Build and start
docker-compose build --no-cache api
docker-compose up -d

log_info "Waiting for services to be healthy..."
sleep 15

# Check services
SERVICES=("carchip_postgres" "carchip_redis" "carchip_api")
for SERVICE in "${SERVICES[@]}"; do
    STATUS=$(docker inspect --format='{{.State.Status}}' "$SERVICE" 2>/dev/null || echo "not found")
    if [ "$STATUS" = "running" ]; then
        log_info "$SERVICE: running"
    else
        log_error "$SERVICE: $STATUS"
    fi
done

# ─── Step 9: Run Database Migrations ──────────────────────────────────────────
log_section "Step 9: Database Migrations"

sleep 10 # Wait for Postgres to be fully ready
docker-compose exec -T api npx prisma migrate deploy
log_info "Database migrations applied"

# ─── Step 10: Let's Encrypt SSL (Optional) ────────────────────────────────────
log_section "Step 10: Let's Encrypt SSL (Optional)"

read -p "Set up Let's Encrypt SSL for $DOMAIN? (y/N): " SETUP_SSL
if [[ "$SETUP_SSL" =~ ^[Yy]$ ]]; then
    read -p "Enter your email for Let's Encrypt: " LE_EMAIL

    # Stop nginx to free port 80
    docker-compose stop nginx

    # Get certificate
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --email "$LE_EMAIL" \
        --agree-tos \
        --non-interactive

    # Copy certs to nginx volume
    cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$NGINX_CERTS_DIR/"
    cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$NGINX_CERTS_DIR/"

    # Update nginx.conf to use real certs
    sed -i "s|# ssl_certificate     /etc/nginx/certs/live.*|ssl_certificate     /etc/nginx/certs/fullchain.pem;|g" "$BACKEND_DIR/nginx/nginx.conf"
    sed -i "s|# ssl_certificate_key /etc/nginx/certs/live.*|ssl_certificate_key /etc/nginx/certs/privkey.pem;|g" "$BACKEND_DIR/nginx/nginx.conf"
    sed -i "s|ssl_certificate     /etc/nginx/certs/selfsigned.crt;|# ssl_certificate     /etc/nginx/certs/selfsigned.crt;|g" "$BACKEND_DIR/nginx/nginx.conf"
    sed -i "s|ssl_certificate_key /etc/nginx/certs/selfsigned.key;|# ssl_certificate_key /etc/nginx/certs/selfsigned.key;|g" "$BACKEND_DIR/nginx/nginx.conf"

    # Restart nginx
    docker-compose start nginx

    # Setup auto-renewal
    (crontab -l 2>/dev/null; echo "0 12 * * * certbot renew --quiet --deploy-hook 'cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $NGINX_CERTS_DIR/ && cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $NGINX_CERTS_DIR/ && docker exec carchip_nginx nginx -s reload'") | crontab -

    log_info "Let's Encrypt SSL configured with auto-renewal"
else
    log_warn "Skipping Let's Encrypt. Using self-signed certificate."
fi

# ─── Step 11: Setup Log Rotation ──────────────────────────────────────────────
log_section "Step 11: Log Rotation"

cat > /etc/logrotate.d/carchip <<EOF
$BACKEND_DIR/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    postrotate
        docker exec carchip_api kill -SIGUSR1 1 2>/dev/null || true
    endscript
}
EOF

log_info "Log rotation configured"

# ─── Step 12: Create Update Script ────────────────────────────────────────────
cat > /usr/local/bin/carchip-update <<'UPDATESCRIPT'
#!/bin/bash
set -euo pipefail
echo "Updating Carchip Backend..."
cd /opt/carchip
git pull origin main
cd backend
docker-compose build --no-cache api
docker-compose up -d api
docker-compose exec -T api npx prisma migrate deploy
echo "Update complete!"
UPDATESCRIPT
chmod +x /usr/local/bin/carchip-update

log_info "Update script created at /usr/local/bin/carchip-update"

# ─── Deployment Summary ────────────────────────────────────────────────────────
log_section "Deployment Complete!"

PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")

echo -e "${GREEN}"
echo "  Carchip Backend is running!"
echo ""
echo "  API URL:        https://$DOMAIN/api/v1"
echo "  Health Check:   https://$DOMAIN/health"
echo "  Server IP:      $PUBLIC_IP"
echo ""
echo "  Useful Commands:"
echo "    View logs:       docker-compose -f $BACKEND_DIR/docker-compose.yml logs -f api"
echo "    Restart API:     docker-compose -f $BACKEND_DIR/docker-compose.yml restart api"
echo "    Stop all:        docker-compose -f $BACKEND_DIR/docker-compose.yml down"
echo "    Update app:      carchip-update"
echo "    DB shell:        docker exec -it carchip_postgres psql -U carchip_user -d carchip_db"
echo ""
echo -e "${NC}"

log_warn "IMPORTANT: Make sure to:"
log_warn "1. Point DNS A record for $DOMAIN to $PUBLIC_IP"
log_warn "2. Review and secure your .env file (chmod 600 $BACKEND_DIR/.env)"
log_warn "3. Set up database backups"
