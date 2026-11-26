# Görüldü iOS

WhatsApp sohbet dışa aktarımını okuyup grubun "karnesini" çıkaran uygulamanın iOS tarafı. Kim en çok yazıyor, kim geç dönüyor, kim gece ortaya çıkıyor, en çok hangi kelime geçiyor; hepsi hikâye kartları olarak gösterilir.

- Dil: Swift, SwiftUI. Üçüncü parti bağımlılık yok.
- En düşük sürüm: iOS 18. Yalnızca iPhone, dikey.
- Paket kimliği: `technology.mika.goruldu`
- Diğer repolar: [Goruldu-Android](https://github.com/m3rtkoksal/Goruldu-Android), [Goruldu-Api](https://github.com/m3rtkoksal/Goruldu-Api)

## Gizlilik sözü

Mesaj metinleri telefondan çıkmaz ve saklanmaz. Dosya bellekte okunur, karne hesaplanır, geriye yalnızca hesaplanan karne (`SavedReport`) JSON olarak kaydedilir. Yapay zeka dalgası için API'ye yalnızca isimler ve sayılar gider. WhatsApp'ın uygulamaya kopyaladığı dosya okunur okunmaz silinir.

## Çalıştırma

1. `Goruldu.xcodeproj` dosyasını Xcode 16 veya üstüyle aç.
2. `Goruldu` şemasını seç, bir iPhone simülatöründe çalıştır.
3. "Sohbet yükle" ekranındaki **Örnek karneyi gör** ile uygulama içindeki örnek sohbet (`Resources/lise-tayfa.txt`, sentetik veri) denenebilir.

Dalga kartının dolması için API'nin çalışıyor olması gerekir. Debug derlemesi simülatörden `http://localhost:5831` adresine bağlanır; [Goruldu-Api](https://github.com/m3rtkoksal/Goruldu-Api) reposunda `npm run start:dev` yeterli. API yoksa kart hata durumunu ve "Tekrar dene" düğmesini gösterir, sahte sonuç üretmez.

## Ayarlar

Ortama göre değişen değerler `Configuration/` altındaki xcconfig dosyalarından Info.plist'e, oradan `AppConfig`'e gelir. Kaynak kodda adres ya da anahtar yoktur.

| Değer | Nerede | Not |
| --- | --- | --- |
| `GORULDU_API_BASE_URL` | `Debug.xcconfig`, `Release.xcconfig` | Release'te boş. API yayına alınınca `Local.xcconfig` içinde verilir. |
| `GORULDU_APP_KEY` | `Local.xcconfig` | API'de `APP_KEY` tanımlıysa aynı değer. |
| `GORULDU_PRIVACY_URL`, `GORULDU_TERMS_URL` | `Base.xcconfig` | Şu an `https://example.com/`. Yayından önce gerçek sayfalarla değişmeli. |

`Configuration/Local.xcconfig` repoya girmez. Örneği: `Configuration/Local.xcconfig.example`. Repo herkese açık olduğu için anahtar, sertifika ve benzeri hiçbir gizli dosya eklenmez.

## Abonelik

StoreKit 2 kullanılır (`Services/PremiumStore.swift`). Fiyatlar her zaman mağazadan okunur.

| Ürün | Kimlik |
| --- | --- |
| Yıllık | `technology.mika.goruldu.premium.yearly` |
| Haftalık | `technology.mika.goruldu.premium.weekly` |

Bu iki ürünün App Store Connect'te tek bir abonelik grubunda açılması gerekir. Yerelde denemek için şema `Configuration/Goruldu.storekit` dosyasını kullanır; içindeki fiyatlar yalnızca deneme değeridir. Debug derlemesinde Ayarlar'da "Premium'u aç (debug)" anahtarı vardır; Release derlemesinde derlenmez.

## Klasörler

| Klasör | İçerik |
| --- | --- |
| `App/` | Giriş noktası, gezinme durumu (`AppModel`), kök görünüm |
| `Core/` | Karne motoru: ayrıştırıcı, kurallar, zip okuyucu. Yalnızca Foundation kullanır |
| `Features/<Alan>/` | Ekranlar: Welcome, Home, Import, Analyzing, Story, Paywall, Share |
| `Services/` | Kayıt, içe aktarma, dalga istemcisi, abonelik, biçimlendirme, metinler |
| `Models/` | `SavedReport`, `Roast`, `StoryCard` |
| `DesignSystem/` | Renkler, yazı tipleri, ortak bileşenler |
| `Resources/` | Yazı tipleri, görseller, `Localizable.xcstrings` (TR + EN), örnek sohbet |
| `Configuration/` | Info.plist, xcconfig dosyaları, StoreKit deneme dosyası |
| `tests/` | `CoreTests` (motor, Linux'ta da çalışır), `AppTests` (uygulama, simülatörde) |

## Karne kuralları

Kuralların tek kaynağı [Goruldu-Api](https://github.com/m3rtkoksal/Goruldu-Api) reposundaki `karne/` klasörüdür (`KARNE-KURALLARI.md`, referans uygulama, örnek dosyalar). iOS ve Android motorları aynı örnek dosyalar için birebir aynı çıktıyı vermek zorundadır; `tests/CoreTests/Fixtures/` altındaki `*.expected.json` dosyaları bunu sınar. Kural değişirse önce `karne/` güncellenir, sonra örnek dosyalar buraya kopyalanır.

## Testler

```bash
# Karne motoru, Xcode gerekmez (macOS ya da Linux):
swift test

# Metin anahtarları (kodda kullanılan her anahtar iki dilde de var mı):
python3 scripts/check-strings.py

# Uygulamanın tamamı, simülatörde:
xcodebuild test -project Goruldu.xcodeproj -scheme Goruldu \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Aynı üç adım her push'ta GitHub Actions'ta çalışır (`.github/workflows/ci.yml`).

## Tasarım

Ekranlar `goruldu-tasarim` prototipinden birebir taşındı (ölçüler px → pt). Yazı tipleri Bricolage Grotesque ve Instrument Sans; ikisi de SIL Open Font License ile dağıtılır, lisans metinleri `Resources/Fonts/` içindedir.
