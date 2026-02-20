# Green Guide (Flutter/Dart)

Starter app sesuai konsep Figma: splash → onboarding → beranda dengan pencarian, filter (jenis tanah, ketinggian, pH, curah hujan), list rekomendasi, detail tanaman, bottom navigation (Beranda/Eksplor/Favorit/Profil).

## Cara Menjalankan
```bash
flutter pub get
flutter run
```
> Minimum Flutter 3.24+

## Struktur
- `lib/main.dart` – entry app + Material3
- `lib/app_router.dart` – routing sederhana
- `lib/theme.dart` – tema warna, font
- `lib/models/plant.dart` – model data
- `lib/services/recommendation_service.dart` – load & filter data dummy
- `lib/providers.dart` – Riverpod state untuk filter
- `lib/screens/*` – layar utama
- `lib/widgets/*` – komponen reusable
- `assets/mock/plants.json` – data contoh

## Kustomisasi
- Sesuaikan daftar `landTypes` pada `FilterSheet` dengan kebutuhan.
- Ganti file `assets/mock/plants.json` dengan dataset riset TA Anda.
- Untuk autentikasi, tambahkan layar Login/Register dan penyimpanan favorit di `shared_preferences`/backend.

Lisensi: MIT (bebas dipakai untuk TA).
