#!/usr/bin/env bash
# render_traefik_dynamic_files.sh
# Şablonları .env değişkenleriyle doldurur → traefik/dynamic

set -x  # Debug: komutları göster


# envsubst kurulu mu?
if command -v envsubst >/dev/null 2>&1; then
  HAVE_ENVSUBST=true
else
  HAVE_ENVSUBST=false
  echo "[UYARI] envsubst bulunamadı – şablon dosyaları doğrudan kopyalanacak."
fi

# Proje kökü (scripts/ bir üst dizin)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
TEMPLATE_DIR="$PROJECT_ROOT/traefik/templates"
DYNAMIC_DIR="$PROJECT_ROOT/traefik/dynamic"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[HATA] .env bulunamadı: $ENV_FILE"
  echo "Lütfen env.ornek dosyasını kopyalayıp .env adıyla proje köküne koyun."
  exit 1
fi

# .env'i kaynakla
set -a
source "$ENV_FILE"
set +a

mkdir -p "$DYNAMIC_DIR"
shopt -s nullglob
templates=($TEMPLATE_DIR/*.yml $TEMPLATE_DIR/*.yaml)

if [[ ${#templates[@]} -eq 0 ]]; then
  echo "[UYARI] $TEMPLATE_DIR içinde şablon dosyası bulunamadı."
  exit 0
fi

for tmpl_path in "${templates[@]}"; do
  tmpl_file="$(basename "$tmpl_path")"
  printf "\n--- %s işleniyor ---\n" "$tmpl_file"

  # kullanılan değişkenleri bul
  vars=$(grep -oE '\$\{?[A-Za-z_][A-Za-z0-9_]*\}?' "$tmpl_path" |
          sed -E 's/\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/\1/' | sort -u)

  if [[ -z "$vars" ]]; then
    echo "[BİLGİ] Şablonda değişken yok."
  else
    echo "Kullanılan değişkenler:"
    missing=()
    for v in $vars; do
      printf " - %s=" "$v"
      if [[ -z "${!v+x}" ]]; then
        echo "<YOK>"
        missing+=("$v")
      else
        echo "${!v}"
      fi
    done
    if (( ${#missing[@]} )); then
      echo "[UYARI] .env içinde bulunmayan değişkenler: ${missing[*]}"
    fi
  fi

  rendered="$DYNAMIC_DIR/$tmpl_file"
  if $HAVE_ENVSUBST; then
    envsubst < "$tmpl_path" > "$rendered"
    echo "Render edilmiş dosya (envsubst): $rendered"
  else
    cp "$tmpl_path" "$rendered"
    echo "Kopyalanan dosya (envsubst yok): $rendered"
  fi
done

echo -e "\nTüm işlemler tamamlandı."