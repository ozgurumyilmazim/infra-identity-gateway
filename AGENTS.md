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

