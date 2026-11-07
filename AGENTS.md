# Proje Genel Kuralları ve Çoklu Ajan Protokolü

Bu proje, çoklu ajan (multi-agent) mimarisiyle geliştirilmektedir. Tüm ajanlar aşağıdaki kurallara uymak zorundadır:

## 1. Genel Kurallar
* **Dil:** Tüm açıklama, yorum satırları ve dokümantasyonlar Türkçe olacaktır. Kod içerisindeki değişken ve fonksiyon adları İngilizce standartlarına uygun yazılacaktır.
* **Kod Kalitesi:** Temiz kod (Clean Code) prensiplerine uyulacak, gereksiz karmaşadan kaçınılacaktır.
* **Dosya Güvenliği:** Ajanlar sadece kendi yetki alanlarındaki dosyalarda değişiklik yapabilir.

## 2. Ajanlar Arası İş Birliği Akışı
1. **Planner (Planlayıcı):** Kullanıcı isteğini alır, adımlara böler ve bir yol haritası (`WORKFLOW_STATE.md`) oluşturur.
2. **Coder (Uygulayıcı):** Planlanan adımları sırasıyla koda döker, gerekli dosyaları oluşturur veya günceller.

## 3. Ekip ve Çalışma Ortamı

* **Ekip:** Proje, proje sahibi ve ekibi tarafından geliştirilmektedir. Ajanlar da bu ekibin bir parçasıdır.
* **Geliştirici ortamları:** Ekip üyeleri hem **Windows** hem **Linux** işletim sistemlerini kullanmaktadır.
* **Hedef (üretim) sistemi:** **Linux**.

### Bu Bağlamdan Doğan Zorunlu Kurallar

* Depoya eklenen tüm betikler ve yapılandırmalar **Linux hedef sistemde** çalışacak şekilde yazılmalıdır.
* Bash betikleri ve konteynerlere mount edilen dosyalar **LF satır sonu** ile saklanmalıdır. Windows'ta `core.autocrlf` kaynaklı CRLF dönüşümü betikleri bozabileceği için `.gitattributes` ile satır sonları sabitlenmelidir.
* Windows'a özgü yol, kabuk komutu veya araç varsayımları paylaşılan koda konulmamalıdır.
* Dosya yolu büyük/küçük harf duyarlılığı Linux'ta geçerlidir; dosya adları buna göre tutarlı yazılmalıdır.
* Değişiklikler hem Windows hem Linux geliştiricilerde çalışacak şekilde doğrulanmalı; nihai kabul ölçütü Linux hedef ortamdır.

### Geliştirme Ortamı Kurulumu (Satır Sonları ve Hook)

Her geliştirici klonu bir kez aşağıdaki komutu çalıştırarak paylaşılan pre-commit hook'unu etkinleştirmelidir:

```bash
git config core.hooksPath .githooks
```

Mevcut bir Windows klonunda dosyaları LF'e dönüştürmek için (önce commit veya stash yapılmalı; `reset --hard` izlenen dosyalardaki yerel değişiklikleri siler):

```bash
git rm --cached -r .
git reset --hard
```

Windows'ta `core.autocrlf` ayarını değiştirmeye gerek yoktur; `.gitattributes` bu ayarı geçersiz kılar.

## 4. Gizli Bilgi (Secret) Yönetimi

* **Temel kural:** Üretilen hiçbir gizli değer (parola, token, API anahtarı, özel anahtar, parola hash'i) git tarafından izlenen bir dosyaya yazılmamalıdır. Gizli değerler yalnızca `.env` veya `.gitignore` ile hariç tutulmuş çalışma zamanı dosyalarında tutulur.
* **Şablonlar:** Repoya yalnızca yer tutucu içeren şablonlar girer: `${DEGISKEN}`, `<ACIKLAMA>` veya boş değer. `env.ornek` gerçek parola, token veya varsayılan kimlik bilgisi içermemelidir.
* **Üretilen dosyalar:** `setup-env.sh` ve `run.sh` tarafından üretilen dosyalar izlenmemelidir: `.env`, `pgadmin/pgpass`, `pgadmin/servers.json`, `pgadmin/config_local.py`, `crowdsec/config.yaml.local`, `traefik/dynamic/*.yml`, `traefik/dynamic/usersfile`, `traefik/certs/*`, `traefik/plugins-local/*`. `.gitignore`'da bulunmaları izlenmedikleri anlamına gelmez; `git ls-files` ile doğrulanır.
* **Şablon kopyaları:** Bu dosyaların yer tutucu içeren örnekleri `crowdsec/config.yaml.local.example` ve `pgadmin/servers.json.example` olarak izlenir; gerçek çıktılar çalışma zamanında üretilir.
* **Zorla ekleme yasağı:** Gizli değer içeren veya çalışma zamanında üretilen dosyalar `git add -f` ile zorla eklenmez.
* **Sızıntı halinde:** Değer derhal döndürülür (rotate), git geçmişinden temizlenir ve ekip bilgilendirilir. Dosyayı silmek veya yeni bir commit atmak tek başına yeterli değildir.
* **Kontrol:** Yeni dosya veya betik eklerken gizli değer üreten çıktının hedefi doğrulanır: `git check-ignore --no-index -v <dosya>` ve `git ls-files <dosya>`.
* **Araçlar:** Pre-commit sırasında `gitleaks` kuruluysa otomatik tarama yapılır; CI'da zorunludur. Kurulum: `winget install gitleaks`, `choco install gitleaks`, `brew install gitleaks` veya GitHub Releases.

