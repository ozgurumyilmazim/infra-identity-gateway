#!/usr/bin/env bash

# render_crowdsec_dynamic_files.sh
# Bu betik, crowdsec/templates dizinindeki şablon dosyalarını .env dosyasındaki
# değişkenlerle doldurur ve sonuçları crowdsec klasörüne yazar.
# Kullanım: proje kök dizininde .env dosyası (env.ornek kopyalanıp düzenlenmiş) bulunmalı.

set -euo pipefail
set -x   # Debug: yürütülen komutları göster

# envsubst kurulu mu?
if command -v envsubst >/dev/null 2>&1; then
  HAVE_ENVSUBST=true
else
  HAVE_ENVSUBST=false
  echo "[UYARI] envsubst bulunamadı – şablon dosyaları doğrudan kopyalanacak."
fi

# Proje kök dizini (scripts/ bir üst klasör)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
TEMPLATE_DIR="$PROJECT_ROOT/crowdsec/templates"
OUTPUT_DIR="$PROJECT_ROOT/crowdsec"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[HATA] .env dosyası bulunamadı: $ENV_FILE"
  echo "Lütfen env.ornek dosyasını kopyalayıp .env adıyla proje köküne koyun."
  exit 1
fi

# .env'i kaynakla, tüm değişkenleri ortam değişkeni yap
set -a
source "$ENV_FILE"
set +a

# output klasörü oluştur (eğer yoksa)
mkdir -p "$OUTPUT_DIR"

shopt -s nullglob
templates=($TEMPLATE_DIR/*.tmpl $TEMPLATE_DIR/*.tmpl)
if [[ ${#templates[@]} -eq 0 ]]; then
  echo "[UYARI] $TEMPLATE_DIR içinde şablon dosyası bulunamadı."
  exit 0
fi

for tmpl_path in "${templates[@]}"; do
  tmpl_file="$(basename "$tmpl_path")"
  # .tmpl uzantısını kaldır ve aynı adı output olarak kullan
  output_file="${tmpl_file%.tmpl}"
  output_path="$OUTPUT_DIR/$output_file"

  printf "\n--- %s işleniyor ---\n" "$tmpl_file"

  # kullanılan değişkenleri göster (opsiyonel)
  vars=$(grep -oE '\$\{?[A-Za-z_][A-Za-z0-9_]*\}?' "$tmpl_path" |
        sed -E 's/\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/\1/' | sort -u)
  if [[ -n "$vars" ]]; then
    echo "Kullanılan değişkenler:"
    for v in $vars; do
      printf " - %s=" "$v"
      if [[ -z "${!v+x}" ]]; then
        echo "<YOK>"
      else
        echo "${!v}"
      fi
    done
  fi

  if $HAVE_ENVSUBST; then
    envsubst < "$tmpl_path" > "$output_path"
    echo "Render edilmiş dosya (envsubst): $output_path"
  else
    cp "$tmpl_path" "$output_path"
    echo "Kopyalanan dosya (envsubst yok): $output_path"
  fi
done

echo -e "\nTüm CrowdSec şablonları işlendi."

