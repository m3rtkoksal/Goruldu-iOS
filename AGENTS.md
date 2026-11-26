# Görüldü iOS: çalışma kuralları

Bu dosya bu repoda kod yazan herkes (insan ya da ajan) içindir. Genel tanıtım için `README.md`.

## Değişmez kurallar

1. **Mesaj metni saklanmaz, gönderilmez, loglanmaz.** Kalıcı olarak yalnızca `SavedReport` yazılır. API'ye yalnızca `RoastService.body` içindeki alanlar (isimler ve sayılar) gider. Yeni bir alan eklemeden önce bu sözü bozup bozmadığına bak.
2. **Repo herkese açık.** Anahtar, sertifika, `.p8`, `Local.xcconfig`, `GoogleService-Info.plist` ve benzeri hiçbir gizli dosya commit edilmez. Sahibi olmadığımız bir alan adı koda ya da ayarlara yazılmaz.
3. **Karne kuralları tek kaynaktan gelir.** `Core/` içindeki motor, Goruldu-Api reposundaki `karne/reference/report.py` ile birebir aynı çıktıyı verir. Kural değişikliği önce orada yapılır, örnek dosyalar (`tests/CoreTests/Fixtures/`) oradan kopyalanır, sonra Swift ve Kotlin motorları güncellenir. `*.expected.json` dosyaları elle düzeltilmez.
4. **Başarı taklit edilmez.** Ağ, mağaza ya da dosya hatası kullanıcıya gösterilir; yerine uydurma sonuç konmaz. Hata yutulmaz (`try?` yalnızca sonucu gerçekten önemsiz olan yerde ve yorumuyla).
5. **Fiyat koda yazılmaz.** Her zaman `Product.displayPrice` kullanılır.

## Kod kuralları

- Swift, SwiftUI, `@Observable`. Üçüncü parti bağımlılık eklenmez.
- `!` ile zorla açma, `try!`, `as!` ve `print` yok.
- `Core/` yalnızca Foundation kullanır; `swift test` ile Linux'ta derlenebilmelidir. UIKit, SwiftUI ya da Apple'a özel çatı buraya girmez.
- Metin karşılaştırmaları `Core/` içinde Unicode skaler düzeyinde yapılır (`TextRules`). `String` karşılaştırması ya da `Character` kullanmak Android ile farklı sonuç verir.
- Kullanıcıya görünen her metin `Resources/Localizable.xcstrings` içinde, Türkçe ve İngilizce olarak durur ve `L10n.tr("anahtar")` ile okunur. Anahtar ekleyip çıkardıktan sonra `python3 scripts/check-strings.py` çalıştır.
- Renk ve yazı tipi doğrudan yazılmaz; `Palette`, `Font.display`, `Font.ui` kullanılır.
- Sayılar `Format.number`, süreler `Format.duration`, yüzdeler `Format.percent` ile yazılır.
- Yorumlar İngilizce ve yalnızca kodun kendisinin anlatamadığı niyeti açıklar.

## Her ekranda beş durum

Yeni ya da değişen her ekran şunları ele alır: boş, yükleniyor, hata, uzun metin, eksik veri. Örnekler: `HomeView` (boş liste, okunamayan kayıt notu), `RoastCard` (yükleniyor, hata, tekrar dene), `PaywallView` (fiyat yükleniyor, mağazaya ulaşılamadı), `WinnerName` (uzun isim küçülür), `StoryCard.cards(for:)` (verisi olmayan kart gösterilmez).

## Proje dosyası

`Goruldu.xcodeproj` dosya sistemiyle eşlenen klasörler kullanır: `App`, `Core`, `DesignSystem`, `Features`, `Models`, `Resources`, `Services` uygulama hedefine, `tests` test hedefine bağlıdır. Bu klasörlere eklenen dosya kendiliğinden hedefe girer; proje dosyasını elle düzenlemek gerekmez. `Configuration/` hiçbir hedefe kopyalanmaz.

Kökteki `Package.swift` yalnızca `Core/` ile `tests/CoreTests/` klasörlerini Xcode'suz derleyip sınamak içindir; uygulama oradan derlenmez.

## Bitirmeden önce

```bash
swift test
python3 scripts/check-strings.py
xcodebuild test -project Goruldu.xcodeproj -scheme Goruldu \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Xcode yoksa ilk ikisini çalıştır, üçüncüsü için push sonrası GitHub Actions sonucuna bak ve sonucu açıkça yaz: neyin sınandığını, neyin sınanamadığını.

## Elle sınanması gerekenler

Aşağıdakiler otomatik testle kapsanmıyor; değiştirdiysen gerçek cihazda dene ve denediğini belirt:

- WhatsApp'tan "Sohbeti dışa aktar" ile dosyanın uygulamaya gelmesi
- Satın alma, geri yükleme, onay bekleyen satın alma
- Kartın fotoğraflara kaydedilmesi ve paylaşım sayfası
