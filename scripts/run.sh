#!/usr/bin/env bash
set -e

# -----------------------------------------------------------------
# Proje kök dizini ve script dizini
# -----------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# -----------------------------------------------------------------
# Renkler
# -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# -----------------------------------------------------------------
# .env dosyasını oku ve çevre değişkenlerini export et
# -----------------------------------------------------------------
get_env_val() {
    grep -E "^${1}=" .env | cut -d '=' -f2- | tr -d '\r' | sed 's/^"\(.*\)"$/\1/'
}
expand_env_refs() {
    local value="$1"
    value=${value//\${DOMAIN_INT}/$DOMAIN_INT}
    value=${value//\${DOMAIN_EXT}/$DOMAIN_EXT}
    printf '%s' "$value"
}
for key in DOMAIN_INT DOMAIN_EXT TRUSTED_SUBNET ACME_EMAIL CROWDSEC_BOUNCER_API_KEY \
           OPNSENSE_INT_FQDN OPNSENSE_EXT_FQDN OPNSENSE_INTERNAL_IP OPNSENSE_INTERNAL_PORT; do
    val=$(get_env_val "$key")
    val=$(expand_env_refs "$val")
    export "${key}=${val}"
done

# Validate required variables
missing=false
for var in TRUSTED_SUBNET DOMAIN_EXT ACME_EMAIL; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}[X] Required env var $var is not set or empty${NC}"
        missing=true
    fi
done
if $missing; then
    exit 1
fi

# -----------------------------------------------------------------


# -----------------------------------------------------------------
# Docker compose çalıştırma (kalan script aynı kalır)
# -----------------------------------------------------------------
cd "$PROJECT_ROOT"

# 2. Veritabanını ve Şemaları Ayağa Kaldır
if [ ! -f "$SCRIPT_DIR/setup-db.sh" ]; then
    echo -e "${RED}[X] $SCRIPT_DIR/setup-db.sh betiği bulunamadı!${NC}"
    exit 1
fi
echo -e "\n${YELLOW}[ADIM 2/4] Merkezi veritabanı ve servis kullanıcıları hazırlanıyor...${NC}"
chmod +x "$SCRIPT_DIR/setup-db.sh"
"$SCRIPT_DIR/setup-db.sh"

# 3. Tüm Yığını Başlat
echo -e "\n${YELLOW}[ADIM 3/4] Servis yığını devreye alınıyor...${NC}"
docker compose up -d

echo -e "\n${GREEN}[✓] Tüm servisler ve alan adları başarıyla devreye alındı.${NC}\n"
docker compose ps

echo -e "\n${BLUE}==============================================${NC}"
echo -e "${BLUE}  Sistem aktif! Traefik logları izleniyor...  ${NC}"
echo -e "${BLUE}  (Çıkmak için Ctrl+C tuşlayabilirsiniz)      ${NC}"
echo -e "${BLUE}==============================================${NC}"
docker compose logs -f --tail=30 traefik