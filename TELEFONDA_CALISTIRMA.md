# 📱 Telefonda Çalıştırma Rehberi

## Android Telefon

### 1. Geliştirici Seçeneklerini Aktifleştirin
1. Telefonunuzda **Ayarlar** > **Telefon Hakkında** gidin
2. **Yapı Numarası**'na 7 kez tıklayın
3. "Geliştirici oldunuz" mesajı görünecek

### 2. USB Hata Ayıklamayı Açın
1. **Ayarlar** > **Geliştirici Seçenekleri** gidin
2. **USB Hata Ayıklama** seçeneğini açın
3. **USB üzerinden yüklemeye izin ver** seçeneğini açın (varsa)

### 3. Telefonu Bilgisayara Bağlayın
1. USB kablosuyla telefonu bilgisayara bağlayın
2. Telefonda "USB hata ayıklamaya izin ver" mesajı çıkacak
3. **İzin Ver** veya **Tamam** seçin
4. "Bu bilgisayara her zaman güven" kutusunu işaretleyin

### 4. Cihazı Kontrol Edin
```bash
flutter devices
```

### 5. Uygulamayı Çalıştırın
```bash
flutter run
```

## iOS (iPhone/iPad)

### 1. Apple Developer Hesabı Gerekli
- Ücretsiz Apple ID ile de test edebilirsiniz
- Xcode'da Apple ID'nizi ekleyin

### 2. Xcode'da Proje Ayarları
1. Xcode'da projeyi açın: `open ios/Runner.xcworkspace`
2. Runner > Signing & Capabilities
3. Team seçin (Apple ID)
4. Bundle Identifier düzenleyin

### 3. Telefonu Güvenilir Cihaz Yapın
1. iPhone'u USB ile bağlayın
2. iPhone'da "Bu bilgisayara güven" seçin
3. iPhone Ayarlar > Genel > VPN ve Cihaz Yönetimi
4. Geliştirici uygulamasına güven

### 4. Çalıştırın
```bash
flutter run
```

## Sorun Giderme

### Cihaz Görünmüyor
```bash
flutter doctor
adb devices      # Android için
```

### Yetki Hatası (Android)
```bash
adb kill-server
adb start-server
```

### Port Kullanımda Hatası
```bash
flutter clean
flutter pub get
flutter run
```
