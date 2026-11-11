#!/usr/bin/env bash
# traefik/dynamic dizinindeki YAML dosyalarını kontrol eden bash betiği.
# Gereksinim: Python 3 ve PyYAML paketi (pip install pyyaml)
# Kullanım:   bash scripts/check_traefik_yaml.sh

set -euo pipefail

# Traefik dinamik yapılandırma dizini (script'in bulunduğu klasörden iki seviye üstte)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../traefik/dynamic" && pwd)"

if [[ ! -d "$BASE_DIR" ]]; then
  echo "[HATA] $BASE_DIR dizini bulunamadı."
  exit 1
fi

# YAML dosyalarını bul
mapfile -t yaml_files < <(find "$BASE_DIR" -type f \( -iname "*.yml" -o -iname "*.yaml" \))

if (( ${#yaml_files[@]} == 0 )); then
  echo "[BİLGİ] Kontrol edilecek YAML dosyası bulunamadı."
  exit 0
fi

has_error=0

for file in "${yaml_files[@]}"; do
  if ! python3 - <<PYEOF
import sys, yaml
with open(r"$file", "r", encoding="utf-8") as f:
    yaml.safe_load(f)
PYEOF
  then
    echo "[HATA] $file dosyasında YAML hatası."
    has_error=1
  fi
done

if (( has_error == 0 )); then
  echo "[İŞLEM TAMAMLANDI] Tüm YAML dosyaları geçerli."
fi

exit $has_error