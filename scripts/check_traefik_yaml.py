#!/usr/bin/env python3
"""traefik/dynamic dizinindeki YAML dosyalarını kontrol eden script.

Bu script, `traefik/dynamic` altında bulunan tüm ``.yml`` ve ``.yaml``
dosyalarını tarar ve ``PyYAML`` kütüphanesi ile parse etmeye çalışır.
Parse hatası alındığında dosya adı ve hata mesajı ekrana yazdırılır.

Kullanım:
    python scripts/check_traefik_yaml.py

Gerekli paketler:
    pip install pyyaml
"""

import pathlib
import sys
import yaml

def main() -> int:
    # Traefik dinamik yapılandırma dizini
    base_dir = pathlib.Path(__file__).resolve().parents[1] / "traefik" / "dynamic"
    if not base_dir.is_dir():
        print(f"[HATA] {base_dir} dizini bulunamadı.")
        return 1

    yaml_files = list(base_dir.rglob("*.y[ml]"))
    if not yaml_files:
        print("[BİLGİ] Kontrol edilecek YAML dosyası bulunamadı.")
        return 0

    has_error = False
    for file_path in yaml_files:
        try:
            with file_path.open("r", encoding="utf-8") as f:
                yaml.safe_load(f)
        except yaml.YAMLError as exc:
            has_error = True
            print(f"[HATA] {file_path} dosyasında YAML hatası: {exc}")
        except Exception as exc:
            has_error = True
            print(f"[HATA] {file_path} dosyasını okurken beklenmeyen hata: {exc}")

    if not has_error:
        print("[İŞLEM TAMAMLANDI] Tüm YAML dosyaları geçerli.")
    return 1 if has_error else 0

if __name__ == "__main__":
    sys.exit(main())

