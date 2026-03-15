# TG Media Backup

<div align="center">

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

Telegram sohbetlerinizdeki medya dosyalarını kolayca yedekleyin.

</div>

---

## Özellikler

- **Telegram Giriş**: Telefon numarası + SMS kodu + 2FA desteği
- **Sohbet Listesi**: Tüm sohbet, grup ve kanalları görüntüleme ve arama
- **Medya Görüntüleme**: Video, fotoğraf ve dosyaları grid veya liste olarak görüntüleme
- **Çoklu İndirme**: Birden fazla medya seçerek eş zamanlı indirme (1-10 arası ayarlanabilir)
- **İndirme Kontrolü**: Duraklat, devam et, iptal et
- **Depolama Yönetimi**: Thumbnail cache, TDLib dosya cache ve veritabanı boyutlarını görüntüleme ve temizleme
- **Çoklu Dil**: Türkçe ve İngilizce arayüz
- **Güvenlik**: API bilgileri Keychain'de şifreli saklanır
- **Native macOS**: Dark mode, klavye kısayolları, Finder entegrasyonu

---

## Gereksinimler

- **macOS** 14.0 (Sonoma) veya üzeri
- **Xcode** 15.0 veya üzeri
- **Telegram API** bilgileri (ücretsiz — aşağıda açıklanıyor)

---

## Kurulum

```bash
git clone https://github.com/vedatermis/TG-Media-Backup.git
cd TG-Media-Backup
open "Telegram Video Downloader.xcodeproj"
```

Xcode açıldığında Swift Package Manager bağımlılığı (TDLibKit) otomatik indirilecektir. Ardından `⌘R` ile çalıştırın.

---

## Telegram API Bilgileri

Uygulama, Telegram'ın resmi API'sini kullanır. API bilgilerinizi almak için:

1. [my.telegram.org](https://my.telegram.org) adresine gidin
2. Telegram hesabınızla giriş yapın
3. **API development tools** bölümüne gidin
4. Yeni uygulama oluşturun (App title: TG Media Backup, Platform: Desktop)
5. **API ID** ve **API Hash** değerlerini kopyalayıp uygulamaya girin

> ⚠️ API bilgilerinizi kimseyle paylaşmayın.

---

## Proje Yapısı

```
Telegram Video Downloader/
├── App/
│   ├── AppState.swift                  # Global state yönetimi
│   └── MainView.swift                  # 3 panelli ana layout
│
├── Core/
│   ├── Models/                         # Data modelleri
│   │   ├── TelegramUser.swift
│   │   ├── TelegramDialog.swift
│   │   ├── TelegramMessage.swift
│   │   ├── MediaItem.swift
│   │   └── DownloadItem.swift
│   └── Managers/                       # Lokalizasyon yönetimi
│       ├── LocalizationManager.swift
│       └── LocalizedStrings.swift
│
├── Features/
│   ├── Auth/                           # Giriş akışı (telefon, kod, 2FA)
│   ├── ChatList/                       # Sohbet listesi ve arama
│   ├── MediaList/                      # Medya grid/liste görünümü
│   ├── Downloader/                     # İndirme kuyruğu
│   └── Settings/                       # Ayarlar (dil, cache, indirme limiti)
│
├── Services/
│   ├── Protocols/                      # Servis arayüzleri
│   └── Implementation/
│       ├── TelegramService.swift       # TDLib entegrasyonu
│       └── ThumbnailManager.swift      # Thumbnail ve cache yönetimi
│
├── Common/
│   ├── Components/                     # LoadingView, ErrorView, EmptyStateView
│   └── Utilities/                      # KeychainHelper, Logger
│
└── Resources/
    ├── en.lproj/Localizable.strings    # İngilizce
    └── tr.lproj/Localizable.strings    # Türkçe
```

---

## Klavye Kısayolları

| Kısayol | İşlev |
|---------|-------|
| `⌘R` | Sohbet listesini yenile |
| `⌘⇧O` | İndirme klasörünü seç |
| `⌘⇧D` | Seçili medyaları indir |

---

## Bağımlılıklar

| Paket | Açıklama |
|-------|----------|
| [TDLibKit](https://github.com/Swiftgram/TDLibKit) | Telegram Database Library Swift wrapper |

---

## Uyarılar

- Bu uygulama Telegram'ın resmi API'lerini kullanır. Hizmet şartlarına uygun kullanın.
- Sadece hakkınız olan içerikleri indirin.
- Aşırı kullanım hesap kısıtlamasına yol açabilir.
- API bilgileriniz Keychain'de güvenle saklanır, kimseyle paylaşmayın.

---

## Lisans

MIT

---

<div align="center">

Made with ❤️ in Turkey 🇹🇷

</div>
