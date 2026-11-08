#!/usr/bin/env bash

# render_traefik_dynamic_files.sh
# Bu betik, traefik/templates dizinindeki YAML şablon dosyalarını .env dosyasındaki
# değişkenlerle doldurur ve sonuçları traefik/dynamic dizinine yazar.
# Kullanım: proje kök dizininde .env dosyası (env.ornek kopyalanıp düzenlenmiş) bulunmalı.

set -euo pipefail
# envsubst komutunun kurulu olup olmadığını kontrol et
if command -v envsubst >/dev/null 2>&1; then
  HAVE_ENVSUBST=true
else
  HAVE_ENVSUBST=false
  echo "[UYARI] envsubst bulunamadı – şablon dosyaları doğrudan kopyalanacak."
fi

# Proje kök dizini (bu betiğin bulunduğu dizinin bir üstü)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ENV_FILE="$PROJECT_ROOT/.env"
TEMPLATE_DIR="$PROJECT_ROOT/traefik/templates"
DYNAMIC_DIR="$PROJECT_ROOT/traefik/dynamic"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[HATA] .env dosyası bulunamadı: $ENV_FILE"
  echo "Lütfen env.ornek dosyasını kopyalayıp .env adıyla proje kök dizinine koyun."
  exit 1
fi

# .env dosyasını kaynaklayarak değişkenleri ortam değişkeni olarak yükle
set -a
# shellcheck disable=SC1091
source "$ENV_FILE"
set +a

# dynamic dizini oluştur (eğer yoksa)
mkdir -p "$DYNAMIC_DIR"

# Şablon dosyalarını işle
shopt -s nullglob
templates=($TEMPLATE_DIR/*.yml $TEMPLATE_DIR/*.yaml)
if [[ ${#templates[@]} -eq 0 ]]; then
  echo "[UYARI] $TEMPLATE_DIR içinde şablon dosyası bulunamadı."
  exit 0
fi

for tmpl_path in "${templates[@]}"; do
  tmpl_file="$(basename "$tmpl_path")"
  echo "\n--- $tmpl_file işleniyor ---"

  # Şablonda kullanılan değişkenleri bul ( ${VAR} veya $VAR )
  vars=$(grep -oE '\$\{?[A-Za-z_][A-Za-z0-9_]*\}?' "$tmpl_path" | sed -E 's/\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/\1/' | sort -u)

  if [[ -z "$vars" ]]; then
    echo "[BİLGİ] Şablonda değişken yok."
  else
    echo "Kullanılan değişkenler:"
    missing=()
    for v in $vars; do
      printf " - %s=" "$v"
      # Değişkenin değeri varsa ekrana yaz, yoksa uyarı
      if [[ -z "${!v+x}" ]]; then
        echo "<YOK>"
        missing+=("$v")
      else
        echo "${!v}"
      fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
      echo "[UYARI] .env içinde bulunmayan değişkenler: ${missing[*]}"
    fi
  fi

  # envsubst ile şablonu render et
  rendered="$DYNAMIC_DIR/$tmpl_file"
  if $HAVE_ENVSUBST; then
    envsubst < "$tmpl_path" > "$rendered"
    echo "Render edilmiş dosya (envsubst): $rendered"
  else
    cp "$tmpl_path" "$rendered"
    echo "Kopyalanan dosya (envsubst yok): $rendered"
  fi
done

echo "\nTüm işlemler tamamlandı."

