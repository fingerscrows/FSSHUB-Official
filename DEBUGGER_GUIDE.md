# 💡 FSSHUB Debugger Module (V4.5) - User Guide

Selamat datang di panduan resmi **FSSHUB Developer Suite**. Tools ini dirancang oleh **SPARK** untuk membantu kamu melakukan debugging, analisis game, dan reverse-engineering dengan mudah dan cepat.

Fitur utama meliputi **Rich Console**, **Performance Monitor**, dan fitur andalan **Deep Object Scanner** yang powerful.

---

## 🚀 Cara Membuka (Quick Start)
Secara default, Debugger terintegrasi ke dalam script utama FSSHUB.
*   **Toggle Key:** Tekan tombol **`F10`** pada keyboard untuk membuka atau menutup UI.
*   **Posisi:** Window bisa di-drag (geser) sesuka hati.
*   **Minimize:** Gunakan tombol `_` di pojok kanan atas untuk mengecilkan window tanpa menutupnya.

---

## 🖥️ Tab 1: Console (Log Viewer)
Tab ini adalah tempat kamu melihat apa yang sedang terjadi di script dan game.

### Fitur Utama:
1.  **Filters (I, W, E):**
    *   **I (Info/Putih):** Log biasa.
    *   **W (Warn/Kuning):** Peringatan (biasanya tidak fatal).
    *   **E (Error/Merah):** Masalah serius/script crash.
    *   *Klik tombol huruf tersebut untuk menyembunyikan/menampilkan jenis log tertentu.*
2.  **Search Bar:** Ketik kata kunci (misal: "player") untuk memfilter log secara instan.
3.  **COPY ALL:** Menyalin semua log yang ada ke clipboard (siap paste ke Notepad/Discord).
4.  **NUKE:** Tombol darurat! Ini akan **menghentikan paksa** semua script FSSHUB (Universal & Game Script) jika terjadi bug parah.

---

## 📡 Tab 2: Smart Scanner (The Power Tool)
Ini adalah fitur "mata dewa" untuk melihat isi game (Workspace) tanpa tool berat seperti Dex Explorer.

### Cara Menggunakan:

#### 1. Target Path (Auto-Discovery)
Kolom ini menentukan **FOLDER MANA** yang ingin kamu scan.
*   **Dropdown Pintar:** Klik tombol `v`. Script akan otomatis mendeteksi folder-folder penting di `workspace` (seperti `Zombies`, `Drops`, `Map`).
*   **Recent History:** Menyimpan 3 lokasi terakhir yang kamu scan.
*   *Contoh:* Pilih `workspace.ServerZombies` untuk melihat musuh.

#### 2. Class Filter (Multi-Select)
Kolom ini menentukan **OBJEK APA** yang ingin dicari.
*   **Multi-Select:** Kamu bisa mencentang lebih dari satu!
    *   Contoh: Centang `[x] Model` DAN `[x] ValueBase`.
*   **Context-Aware:** List dropdown hanya akan menampilkan ClassName yang **benar-benar ada** di dalam folder target. Jadi kamu tidak perlu menebak-nebak.

#### 3. Depth Slider (Deep Scan)
Mengatur seberapa dalam scanner akan "menggali".
*   **1:** Hanya anak langsung (Immediate Children). Cepat & Ringan.
*   **2-3:** Scan anak dan cucu objek (Recommended untuk Folder berisi Model).
*   **4-10:** Sangat dalam. Gunakan hati-hati pada folder besar!

#### 4. Hasil Scan (Smart Peek)
Hasil scan akan muncul dalam format **Tree View** (Pohon) yang rapi. Scanner juga melakukan "Smart Peek" (Mengintip Properti):
*   **Model:** Menampilkan HP (`HP: 100`) atau jumlah anak (`Children: 5`).
*   **Part:** Menampilkan Ukuran (`Size: 2.5`).
*   **Value:** Menampilkan isi value (`= 5000`).
*   **Distance:** Menampilkan jarak objek dari karakter kamu (`[Dist: 15 studs]`).

---

## 📊 Stats Monitor
Tombol **[STATS]** di pojok kanan atas akan memunculkan panel kecil berisi info teknis:
*   **FPS & Ping:** Cek performa jaringan/game.
*   **Memory:** Cek penggunaan RAM.
*   **Character Info:** WalkSpeed, JumpPower, Velocity, dan Posisi Koordinat.
*   **Active Scripts:** Melihat script FSSHUB mana yang sedang berjalan (`[UNI]`, `[WVZ]`).

---

## 💡 Pro Tips dari SPARK

1.  **Mencari Item/Loot:**
    *   Set Path ke `workspace` (atau folder `Drops` jika ada).
    *   Set Depth ke **3**.
    *   Set Class Filter ke `Tool`, `Handle`, atau `TouchTransmitter`.
    *   *Scanner akan menemukan item yang tersembunyi di dalam map!*

2.  **Mencegah Lag:**
    *   Jangan langsung scan `workspace` dengan Depth 10! Mulai dari Depth 1 atau 2.
    *   Jika scanner mendeteksi ribuan objek, ia akan "istirahat" sejenak setiap 500 item (status tombol berubah jadi angka). Tunggu saja sampai selesai.

3.  **Debugger untuk Developer:**
    *   Gunakan `ValueBase` pada Class Filter untuk menemukan "Setting" atau "Config" game yang disembunyikan developer game di dalam folder ReplicatedStorage atau Workspace.

---
*Happy Debugging!* 🚀
