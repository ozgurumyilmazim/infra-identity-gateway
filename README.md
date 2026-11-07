# Infrastructure Identity & Secure Edge Gateway

Merkezi kimlik yönetimi (Univention Corporate Server Samba 4 Active Directory & Zitadel OIDC/SAML), ters vekil (Traefik v3), uzak masaüstü ağ geçidi (Apache Guacamole), parola kasası (Vaultwarden) ve çok katmanlı tünel güvenliğini (Tailscale, Cloudflare, CrowdSec) bir araya getiren kurumsal Docker Compose mimarisi.

## Ağ ve Port Ayrımı

* **Port 80 (`web`):** Dahili HTTP isteklerini doğrudan 443'e (HTTPS) yönlendirir.
* **Port 443 (`websecure`):** Yerel ağ (`.intra`) isteklerini karşılar; Traefik TLS yapılandırması üzerinden hizmet verir.
* **Port 444 (`webexternal`):** Harici tünel ve VPN (`.com.tr`) isteklerini karşılar; seçili rotalar **CrowdSec LAPI Bouncer Plugin** ile korunur.

## Mimarideki Modüller

* **Traefik v3:** Tüm HTTP/HTTPS ve gRPC (h2c) trafiğini yöneten ters vekil.
* **Zitadel:** OpenID Connect ve SAML 2.0 sağlayıcısı (UCS Samba 4 ile federated çalışacak şekilde yapılandırılabilir).
* **Keycloak:** OpenID Connect ve SAML 2.0 sağlayıcısı, UCS LDAP ve diğer uygulamalarla entegrasyon için alternatif IdP.
* **PostgreSQL 16:** Zitadel, Guacamole, Vaultwarden ve CrowdSec için merkezi veritabanı.
* **Portainer CE:** Konteyner yönetim arayüzü.
* **CrowdSec:** Traefik erişim loglarını izleyen saldırı tespit ve engelleme sistemi.
* **Apache Guacamole & Guacd:** Web tabanlı RDP/VNC/SSH istemcisi.
* **Vaultwarden:** Bitwarden uyumlu kurumsal parola yöneticisi.
* **Tailscale & Cloudflare Tunnel:** Güvenli uzaktan erişim ve sıfır-port dış tünelleme.
* **OPNsense:** Harici firewall WebGUI yönlendirmesi.
* **pgAdmin 4:** Merkezi veritabanı yönetim arayüzü.
* **oauth2-proxy:** Traefik ForwardAuth ile Zitadel üzerinden SSO entegrasyonu.

## Kurulum ve Dağıtım

### 1. Depoyu Klonlayın
```bash
git clone git@github.com:ozgurumyilmazim/infra-identity-gateway.git
cd infra-identity-gateway
```

### 2. Çevre Değişkenlerini Hazırlayın
`env.ornek` dosyasını `.env` olarak kopyalayın ve ağ/alan adı bilgilerinizi güncelleyin.
```bash
cp env.ornek .env
```

`.env` içerisinde en az aşağıdaki alanları kendi ortamınıza göre düzenleyin:
- `DOMAIN_INT`, `DOMAIN_EXT`
- `TRUSTED_SUBNET`
- `UCS_*`, `ACME_EMAIL`, `CF_DNS_API_TOKEN`, `TAILSCALE_AUTH_KEY`, `CLOUDFLARE_TUNNEL_TOKEN`
- `OAUTH2_PROXY_CLIENT_ID`, `OAUTH2_PROXY_CLIENT_SECRET`, `OAUTH2_PROXY_COOKIE_SECRET` (Zitadel uygulama kaydı sonrası doldurulabilir)

### 3. Otomatik Yapılandırma ve Başlatma
Tüm yapılandırma dosyaları, şifreler, sertifikalar ve bağımlılıklar `run.sh` ile hazırlanıp başlatılır.
```bash
chmod +x run.sh setup-env.sh setup-db.sh setup-zitadel.sh
./run.sh
```

`run.sh` sırasıyla şunları yapar:
1. `setup-env.sh` - `.env` kontrolü/üretimi, gizli anahtarlar, CrowdSec plugin, Traefik dinamik dosyaları, pgAdmin yapılandırması, htpasswd
2. `setup-db.sh` - PostgreSQL başlatma, kullanıcı/DB oluşturma, Guacamole şeması yükleme
3. `docker compose up -d` - Tüm servisleri ayağa kaldırma
4. `setup-zitadel.sh` - Çift FQDN kullanımı için Zitadel instance domain eşleştirmesi
5. `traefik/templates/*.yml.tmpl` -> `traefik/dynamic/*.yml` üretimi

### 4. Durdurma / Temizlik
```bash
./stop.sh        # Servisleri durdur (hacimler korunur)
./down.sh        # Servisleri ve ağları kaldır (hacimler korunur)
./down.sh -v     # Tüm verileri silerek sıfırlama (dikkatli kullanın)
```

## Önemli Dosya Yapısı

- `docker-compose.yml` - Tüm servis tanımları, ağlar ve hacimler
- `run.sh`, `setup-env.sh`, `setup-db.sh`, `setup-zitadel.sh` - Otomatik kurulum betikleri
- `traefik/templates/` - Traefik dinamik yapılandırma şablonları (`*.yml.tmpl`)
- `traefik/dynamic/` - `run.sh` tarafından şablonlardan üretilen dinamik yapılandırmalar
- `traefik/` - Traefik sertifikaları ve yerel eklentiler
- `crowdsec/` - CrowdSec yapılandırması
- `pgadmin/` - pgAdmin `servers.json`, `pgpass`, `config_local.py`
- `postgres-init/` - İlk PostgreSQL çoklu veritabanı başlatma betiği

## Notlar

- Traefik CrowdSec bouncer eklentisi `setup-env.sh` tarafından GitHub'dan indirilir.
- CrowdSec koleksiyonları: `crowdsecurity/linux`, `crowdsecurity/traefik`, `crowdsecurity/http-dos`, `crowdsecurity/appsec-virtual-patching`, `crowdsecurity/appsec-generic-rules`; Traefik erişim logu ve AppSec (7422) `crowdsec/acquis.d/` üzerinden okunur.
- Vaultwarden admin token `setup-env.sh` ile Argon2 PHC formatında üretilir ve `.env`'ye yazılır.
- pgAdmin kimlik doğrulaması `SERVER_MODE=true` ve `MASTER_PASSWORD_REQUIRED=true` ile yapılandırılır.
- Traefik Dashboard erişimi `traefik/dynamic/usersfile` (htpasswd) ile korunur.
- Harici rotalar için CrowdSec middleware ve gerekli yerlerde ForwardAuth (`oauth2-proxy`) kullanılabilir.
- Üretim ortamında TLS sertifikalarınızı `traefik/certs/` altına `ucs-cert.crt`, `ucs-cert.key` ve `ucs-root-ca.crt` adlarıyla yerleştirin. Yerel kurulumda bulunan sertifikalar yalnızca test için üretilmiş otomatik imzalı (self-signed) sertifikalardır; gerçek UCS Root CA sertifikalarıyla değiştirilmelidir.
- İlk çalıştırmada `.env` yoksa `env.ornek` şablonundan otomatik oluşturulur; boş bırakılan gizli değerler `setup-env.sh` tarafından rastgele üretilir.
- `CF_DNS_API_TOKEN`, `TAILSCALE_AUTH_KEY`, `CLOUDFLARE_TUNNEL_TOKEN` ve `OAUTH2_PROXY_*` değerlerini kendi ortamınıza göre doldurmanız gerekir.

## Vaultwarden, UCS ve İstemci Özellikleri

### UCS LDAP entegrasyonu

Upstream Vaultwarden doğrudan LDAP ile oturum açmayı desteklemez. LDAP yalnızca
kullanıcı davet/senkronu için kullanılabilir. UCS hesaplarıyla merkezi giriş
gerekiyorsa iki yol vardır:

- **Zitadel OIDC SSO:** Zitadel, UCS Samba 4 AD'ye federasyon ile bağlanır ve
  Vaultwarden `SSO_ENABLED=true` ile Zitadel'e yönlendirilir.
- **vaultwarden_ldap:** Kullanıcılar LDAP'ten otomatik davet edilir; Vaultwarden
  ana parolası ayrı kalır.

SSO, Vaultwarden 1.35.0 ile stabil sürüme girdi ancak hâlâ olgunlaşma aşamasında.
Ayrıca sıfır-bilgi mimarisi nedeniyle master parola yine gerekir; SSO yalnızca
kimlik doğrulama/session katmanını devralır. Bu nedenle mevcut kurulumda SSO
etkinleştirilmemiştir. Merkezi onboarding/offboarding gerekirse önce
`vaultwarden_ldap` davet senkronu değerlendirilmelidir.

### Windows 11

- Bitwarden masaüstü uygulamasını Microsoft Store yerine
  [bitwarden.com/download](https://bitwarden.com/download/) üzerinden kurun.
- Windows Ayarları'nda Windows Hello (PIN/yüz/parmak izi) etkin olsun; ardından
  uygulamada `File → Settings → Security → Unlock with Windows Hello` seçin.
- Uygulama yeniden başlatıldığında biyometrik kilit için
  `Require master password or PIN on app restart` seçeneğini kapatın.
- Tarayıcı eklentisini masaüstü uygulamasından açmak için her iki tarafta
  browser integration seçeneğini etkinleştirin.

### Android

- Bitwarden Android uygulamasında self-hosted sunucu URL'si olarak kanonik
  alan adını girin.
- Biyometrik kilit ve Android Autofill, uygulama ayarlarından etkinleştirilir.
- Anlık senkron için WebSocket zaten açıktır. Mobil push bildirimleri istenirse
  `PUSH_ENABLED=true` ile birlikte `PUSH_INSTALLATION_ID` ve
  `PUSH_INSTALLATION_KEY` (bitwarden.com/host) eklenmelidir.

### WebAuthn/FIDO2 2FA ve acil erişim

- WebAuthn/FIDO2 2FA ek yapılandırma gerektirmez; HTTPS ve doğru `DOMAIN`
  yeterlidir.
- WebAuthn kimlik bilgileri alan adına bağlıdır. Bu nedenle Vaultwarden için tek
  kanonik alan adı kullanılır: `VAULTWARDEN_EXT_FQDN`. İç ağdan da bu FQDN'in
  Traefik'e çözülmesi için split-DNS kaydı gerekir.
- Acil erişim `EMERGENCY_ACCESS_ALLOWED=true` ile açıktır.

## Lisans

[LICENSE](LICENSE) dosyasına bakınız.
