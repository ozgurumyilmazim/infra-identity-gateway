#!/usr/bin/env bash
set -e

# Determine script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}        INFRA-IDENTITY-GATEWAY BAŞLATICI      ${NC}"
echo -e "${BLUE}==============================================${NC}"

# 1. Ortam ve Gizli Değişkenleri Hazırla
if [ ! -f "$SCRIPT_DIR/setup-env.sh" ]; then
    echo -e "${RED}[X] "$SCRIPT_DIR/setup-env.sh" betiği bulunamadı!${NC}"
    exit 1
fi
echo -e "\n${YELLOW}[ADIM 1/4] Ortam değişkenleri ve yapılandırma dosyaları kontrol ediliyor...${NC}"
chmod +x "$SCRIPT_DIR/setup-env.sh"
"$SCRIPT_DIR/setup-env.sh"

# .env değişkenlerini (kabuk olarak çalıştırmadan) oku ve dinamik şablonları üret
get_env_val() {
    grep -E "^${1}=" .env | cut -d '=' -f2- | tr -d '\r' | sed 's/^"\(.*\)"$/\1/'
}

expand_env_refs() {
    local value="$1"
    value=${value//\$\{DOMAIN_INT\}/$DOMAIN_INT}
    value=${value//\$\{DOMAIN_EXT\}/$DOMAIN_EXT}
    printf '%s' "$value"
}

for key in DOMAIN_INT DOMAIN_EXT TRUSTED_SUBNET CROWDSEC_BOUNCER_API_KEY \
           OPNSENSE_INT_FQDN OPNSENSE_EXT_FQDN OPNSENSE_INTERNAL_IP OPNSENSE_INTERNAL_PORT; do
    value=$(get_env_val "$key")
    value=$(expand_env_refs "$value")
    export "${key}=${value}"

done

DYNAMIC_DIR="./traefik/dynamic"
TRAEFIK_TEMPLATE_DIR="./traefik/templates"



render_template() {
    local template="$1"
    local output="$2"
    shift 2

    if command -v envsubst >/dev/null 2>&1; then
        envsubst "$*" < "$template" > "$output"
        return
    fi

    local content
    content=$(<"$template")
    local var value
    for var in "$@"; do
        var=${var#\$}
        var=${var#\{}
        var=${var%\}}
        value=${!var:-}
        content=${content//\$\{$var\}/$value}
    done

# Yeni: CrowdSec konfigürasyon şablonu işleme
echo -e "\n${YELLOW}[*] CrowdSec konfigürasyon şablonu işleniyor...${NC}"
CROWDSEC_TEMPLATE_DIR="./crowdsec/templates"
CROWDSEC_OUTPUT="./crowdsec/config.yaml.local"
render_template "$CROWDSEC_TEMPLATE_DIR/config.yaml.local.tmpl" "$CROWDSEC_OUTPUT" "${DOMAIN_EXT}" "${DOMAIN_INT}" "${TRUSTED_SUBNET}" "${CROWDSEC_BOUNCER_API_KEY}" "${OPNSENSE_INT_FQDN}" "${OPNSENSE_EXT_FQDN}" "${OPNSENSE_INTERNAL_IP}" "${OPNSENSE_INTERNAL_PORT}"
echo -e "${GREEN}[✓] config.yaml.local üretildi.${NC}"
    printf '%s\n' "$content" > "$output"
}

# Yeni: CrowdSec konfigürasyon şablonu işleme
echo -e "\n${YELLOW}[*] CrowdSec konfigürasyon şablonu işleniyor...${NC}"
CROWDSEC_TEMPLATE_DIR="./crowdsec/templates"
CROWDSEC_OUTPUT="./crowdsec/config.yaml.local"
render_template "$CROWDSEC_TEMPLATE_DIR/config.yaml.local.tmpl" "$CROWDSEC_OUTPUT" "${DOMAIN_EXT}" "${DOMAIN_INT}" "${TRUSTED_SUBNET}" "${CROWDSEC_BOUNCER_API_KEY}" "${OPNSENSE_INT_FQDN}" "${OPNSENSE_EXT_FQDN}" "${OPNSENSE_INTERNAL_IP}" "${OPNSENSE_INTERNAL_PORT}"
echo -e "${GREEN}[✓] config.yaml.local üretildi.${NC}"

# -------------------------------------------------------------
# Traefik dinamik şablonları işleniyor
# -------------------------------------------------------------
echo -e "\n${YELLOW}[*] Traefik dinamik şablonları işleniyor...${NC}"
mkdir -p "${DYNAMIC_DIR}"

for template in "${TEMPLATE_DIR}"/*.yml.tmpl; do
    [ -e "${template}" ] || continue
    filename=$(basename "${template}" .tmpl)

    # envsubst tüm ortam değişkenlerini otomatik olarak dönüştürür.
    # Bu yüzden render_template fonksiyonuna ekstra argüman geçmiyoruz.
    render_template "${template}" "${DYNAMIC_DIR}/${filename}"

    echo -e "${GREEN}[✓] ${filename} üretildi.${NC}"
done

# Change to project root for Docker commands
cd "$PROJECT_ROOT"
# 2. Veritabanını ve Şemaları Ayağa Kaldır
if [ ! -f "$SCRIPT_DIR/setup-db.sh" ]; then
    echo -e "${RED}[X] "$SCRIPT_DIR/setup-db.sh" betiği bulunamadı!${NC}"
    exit 1
fi
echo -e "\n${YELLOW}[ADIM 2/4] Merkezi veritabanı ve servis kullanıcıları hazırlanıyor...${NC}"
chmod +x "$SCRIPT_DIR/setup-db.sh"
"$SCRIPT_DIR/setup-db.sh"

# 3. Tüm Yığını Başlat
echo -e "\n${YELLOW}[ADIM 3/4] Servis yığını devreye alınıyor...${NC}"
docker compose up -d

# 4. Zitadel Harici Alan Adı Senkronizasyonu
echo -e "\n${YELLOW}[ADIM 4/4] Zitadel alan adı entegrasyonu tamamlanıyor...${NC}"
chmod +x "$SCRIPT_DIR/setup-zitadel.sh"
"$SCRIPT_DIR/setup-zitadel.sh"


echo -e "\n${GREEN}[✓] Tüm servisler ve alan adları başarıyla devreye alındı.${NC}\n"
docker compose ps


echo -e "\n${BLUE}==============================================${NC}"
echo -e "${BLUE}  Sistem aktif! Traefik logları izleniyor...  ${NC}"
echo -e "${BLUE}  (Çıkmak için Ctrl+C tuşlayabilirsiniz)      ${NC}"
echo -e "${BLUE}==============================================${NC}"
docker compose logs -f --tail=30 traefik