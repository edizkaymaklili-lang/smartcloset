# 🚀 Smart Closet - Hızlı Başlangıç Rehberi

## ✅ Kurulum Checklist

### 1️⃣ Firebase Projesi (5 dakika)
- [ ] [Firebase Console](https://console.firebase.google.com) aç
- [ ] "Add project" → İsim: **Smart Closet**
- [ ] Google Analytics aktif et
- [ ] Proje oluşturuldu ✅

### 2️⃣ Android App Ekle (3 dakika)
- [ ] Android ikonu tıkla
- [ ] Package name: `com.example.stil_asist`
- [ ] `google-services.json` indir
- [ ] Dosyayı `android/app/` klasörüne kopyala
- [ ] Android uygulaması eklendi ✅

### 3️⃣ Firestore Database (2 dakika)
- [ ] Build → Firestore Database
- [ ] "Create database"
- [ ] Location: **europe-west1**
- [ ] Production mode
- [ ] Rules sekmesinde güvenlik kurallarını güncelle (FIREBASE_SETUP.md'den kopyala)
- [ ] Firestore aktif ✅

### 4️⃣ Firebase Storage (2 dakika)
- [ ] Build → Storage
- [ ] "Get started"
- [ ] Location: **europe-west1**
- [ ] Rules sekmesinde güvenlik kurallarını güncelle
- [ ] Storage aktif ✅

### 5️⃣ Authentication (2 dakika)
- [ ] Build → Authentication
- [ ] "Get started"
- [ ] Email/Password aktif et
- [ ] Google Sign-In aktif et (support email ekle)
- [ ] Test kullanıcı oluştur: `test@stilasist.com` / `test123456`
- [ ] Authentication aktif ✅

### 6️⃣ Blaze Plan (1 dakika)
- [ ] ⚙️ → Usage and billing
- [ ] "Modify plan" → Blaze (Pay as you go)
- [ ] Billing account ekle
- [ ] **Not**: Günlük limitlere dikkat, free tier çok geniş!
- [ ] Blaze plan aktif ✅

### 7️⃣ Google Maps API Key (5 dakika)
- [ ] [Google Cloud Console](https://console.cloud.google.com) aç
- [ ] Firebase projesini seç
- [ ] APIs & Services → Library
- [ ] "Maps SDK for Android" ara ve aktif et
- [ ] Credentials → Create Credentials → API Key
- [ ] API Key'i kopyala
- [ ] `AndroidManifest.xml` dosyasında `YOUR_GOOGLE_MAPS_API_KEY_HERE` yerine yapıştır
- [ ] Maps API aktif ✅

---

## 🧪 Test Et

### Terminal Komutları:
```bash
cd "C:\Users\DeboMac\Documents\GitHub\Smart Closet"
flutter clean
flutter pub get
flutter run
```

### Uygulamada Test:
1. **Uygulamayı Aç** ✅
2. **Style Feed sekmesine git** (alttaki 3. tab)
3. **"Share Your Style" butonuna bas** (FAB veya + ikonu)
4. **Fotoğraf seç** (galeri veya kamera)
5. **Açıklama ve tag ekle** (#casual, #summer vb.)
6. **Konum izni ver** (isterse)
7. **"Share" butonuna bas**
8. **Feed'de gör** → Post görünüyor mu? ✅
9. **Like tıkla** → Kalp kırmızı oluyor mu? ✅
10. **Map ikonuna tıkla** → Harita açılıyor mu? ✅
11. **Marker tıkla** → Post önizlemesi çıkıyor mu? ✅

---

## 🎯 İlk Veriyi Oluştur

### 5-10 Test Postu:
```
Post 1: Casual outfit (#casual, #jeans, #summer)
Post 2: Office outfit (#formal, #office, #workwear)
Post 3: Night out (#night, #party, #elegant)
Post 4: Sporty outfit (#sporty, #gym, #active)
Post 5: Beach outfit (#beach, #summer, #swimwear)
```

Farklı şehirlerden konum seç (varsa) → Haritada dağınık görünsünler!

---

## 🐛 Sorun Giderme

### "Firebase not initialized"
```bash
# google-services.json doğru yerde mi kontrol et:
ls android/app/google-services.json

# Temizle ve yeniden dene:
flutter clean
flutter pub get
flutter run
```

### "Maps not loading"
- AndroidManifest.xml'de API key var mı?
- Maps SDK for Android aktif mi?
- Internet izni var mı? ✅ (Zaten var)

### "Permission denied"
- Firestore rules doğru mu?
- Authentication yapıldı mı?
- Firebase Console'da Rules sekmesini kontrol et

---

## 📱 Ekran Görüntüleri

Çalışan özellikleri görmek için:
1. Style Feed → Post kartları
2. Map View → Markerlar
3. Create Post → Form
4. Post Preview → Bottom sheet

---

## 🎉 Başarılı Kurulum!

Eğer:
- ✅ Post oluşturabiliyorsun
- ✅ Feed'de görünüyor
- ✅ Like çalışıyor
- ✅ Haritada markerlar var
- ✅ Marker tıklayınca önizleme çıkıyor

**Tebrikler! Firebase başarıyla kuruldu!** 🎊

---

## ⏭️ Sırada Ne Var?

1. **Daha fazla test verisi ekle** (10-20 post)
2. **Farklı tag kombinasyonları dene**
3. **Harita filtrelerini test et**
4. **Phase 3'e geç**: Post detay ekranı, profil sayfası

---

## 📞 Yardım

Sorun mu var? `FIREBASE_SETUP.md` dosyasına detaylı bakın!

**İletişim**: GitHub Issues
