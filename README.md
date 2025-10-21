# 🤖 Robot Edukasi - Aplikasi Kontrol Robot

Aplikasi Flutter untuk mengontrol robot edukasi berbasis Raspberry Pi dengan tema kids-friendly. Aplikasi ini dirancang khusus untuk pembelajaran robotika anak SD-SMP dengan tampilan yang menyenangkan dan mudah dipahami.

## ✨ Fitur Utama

### 🕹️ 1. Kontrol Joystick

- Joystick interaktif untuk mengontrol pergerakan robot
- Perintah: Maju, Mundur, Kiri, Kanan, Berhenti
- Indikator status koneksi real-time
- Auto-reconnect jika koneksi terputus

### 🎤 2. Kontrol Suara

- Voice recognition menggunakan speech-to-text
- Perintah suara dalam Bahasa Indonesia: "maju", "mundur", "kiri", "kanan", "berhenti"
- Animasi mikrofon yang menarik
- Feedback visual dan haptic

### 📋 3. Susun Perintah

- Menyusun urutan perintah robot secara sekuensial
- Drag & drop untuk mengatur ulang urutan
- Simpan ke local storage
- Kirim urutan perintah ke robot dalam format JSON

### 🚪 4. Keluar

- Dialog konfirmasi sebelum keluar aplikasi

## 🎨 Desain Kids-Friendly

- **Warna cerah**: Biru muda, kuning, hijau, merah pastel
- **Font playful**: Google Fonts Nunito
- **Ikon besar**: Mudah ditekan untuk anak-anak
- **Animasi menarik**: Feedback visual yang responsif
- **Gradient background**: Tampilan yang menyenangkan

## 🛠️ Teknologi

- **Flutter 3+** - Framework UI
- **Provider** - State management
- **Socket.io** - Komunikasi real-time dengan Raspberry Pi
- **Speech-to-Text** - Voice recognition
- **Flutter Joystick** - Kontrol joystick
- **Shared Preferences** - Local storage
- **Google Fonts** - Typography

## 📱 Instalasi

1. **Clone repository**

   ```bash
   git clone <repository-url>
   cd ai_cargo_mobile
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

## ⚙️ Konfigurasi

### Raspberry Pi Server

Aplikasi terhubung ke Raspberry Pi melalui Socket.io pada alamat default:

```
http://192.168.4.1:5000
```

Untuk mengubah alamat server:

1. Buka aplikasi
2. Tap ikon pengaturan di home page
3. Masukkan URL server baru
4. Tap "Hubungkan"

### Format Perintah Socket.io

**Joystick Command:**

```json
{
  "command": "forward|backward|left|right|stop",
  "timestamp": 1234567890
}
```

**Voice Command:**

```json
{
  "command": "forward|backward|left|right|stop",
  "timestamp": 1234567890
}
```

**Command Sequence:**

```json
{
  "command": "run_commands",
  "data": [
    { "type": "forward", "duration": 2.0 },
    { "type": "left", "duration": 1.5 },
    { "type": "stop", "duration": 1.0 }
  ],
  "timestamp": 1234567890
}
```

## 🔧 Permissions

Aplikasi memerlukan permissions berikut:

- `INTERNET` - Koneksi ke robot
- `RECORD_AUDIO` - Voice recognition
- `MICROPHONE` - Voice recognition
- `ACCESS_NETWORK_STATE` - Status koneksi
- `VIBRATE` - Haptic feedback

## 📂 Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/
│   └── command_model.dart    # Model data perintah
├── pages/
│   ├── home_page.dart        # Halaman utama
│   ├── joystick_control_page.dart  # Kontrol joystick
│   ├── voice_control_page.dart     # Kontrol suara
│   └── command_sequence_page.dart  # Susun perintah
└── services/
    ├── socket_service.dart   # Service Socket.io
    └── voice_service.dart    # Service voice recognition
```

## 🎯 Target Pengguna

Aplikasi ini dirancang untuk:

- **Anak SD-SMP** (7-15 tahun)
- **Pembelajaran robotika** di sekolah
- **Workshop STEM** untuk anak-anak
- **Proyek edukasi** dengan Raspberry Pi

## 🚀 Cara Penggunaan

1. **Pastikan robot Raspberry Pi aktif** dan terhubung ke jaringan
2. **Buka aplikasi** dan periksa status koneksi
3. **Pilih mode kontrol**:
   - Joystick: Gerakkan joystick untuk mengontrol robot
   - Suara: Tekan mikrofon dan ucapkan perintah
   - Susun Perintah: Buat urutan perintah dan jalankan
4. **Monitor status koneksi** di bagian atas layar
5. **Nikmati pengalaman** mengontrol robot!

## 🔍 Troubleshooting

**Robot tidak terhubung:**

- Periksa alamat IP Raspberry Pi
- Pastikan server Socket.io berjalan di port 5000
- Cek koneksi WiFi

**Voice recognition tidak bekerja:**

- Berikan permission microphone
- Pastikan berbicara dengan jelas
- Coba restart aplikasi

**Joystick tidak responsif:**

- Periksa koneksi internet
- Restart aplikasi
- Cek status koneksi di header

## 📄 Lisensi

Project ini dibuat untuk tujuan edukasi dan pembelajaran robotika anak-anak.
