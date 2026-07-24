# DOKUMEN KEBUTUHAN PRODUK (PRD)

**EDGEBENCH: Runtime Inteligensia On-Device untuk Flutter**

*   **ID Dokumen:** PRD-EDGEBENCH-001
*   **Versi:** 1.0 — Baseline (Dibekukan)
*   **Platform:** Flutter 3.35+ / Dart 3.9+ · Android 10+ (API 29) · iOS 16+
*   **Estimasi Waktu Kerja:** 10–14 minggu, satu engineer, paruh waktu
*   **Tingkat Kesulitan:** Sulit — Sengaja dirancang agar tahan terhadap solusi buatan AI
*   **Sumbu Utama Evaluasi:** Performa dan akurasi di bawah pengukuran, bukan jumlah fitur
*   **Model Penerimaan:** Biner. Setiap gerbang kuantitatif harus lolos, atau rilis ditolak.

## Ringkasan Ringkas Dokumen

Aplikasi Flutter single-binary yang melakukan inferensi bahasa, visi, dan suara sepenuhnya di dalam perangkat (on-device) — tanpa jaringan, tanpa fallback ke cloud, dan tanpa SDK vendor yang mengerjakan bagian sulitnya. Produk akhir yang diserahkan bukanlah aplikasinya, melainkan sebuah pengukuran performa (latensi, memori, dan akurasi) yang valid dan dapat dipertanggungjawabkan pada perangkat keras (hardware) asli.

Sebagian besar "aplikasi AI" saat ini hanyalah HTTP client. Aplikasi ini bukan seperti itu. Pembuat kode AI (LLM) mungkin bisa menghasilkan kode Flutter dan inferensi yang tampak meyakinkan, namun AI tidak bisa merekayasa kurva penurunan performa akibat panas (thermal-throttle), lonjakan latensi p99 saat tekanan memori, atau confusion matrix dari perangkat fisik yang benar-benar ada. Celah itulah yang menjadi poin utama dari latihan ini.

---

## 1 · Definisi Produk

### 1.1 Pernyataan Masalah

Aplikasi seluler yang mengiklankan kemampuan AI hampir secara universal mendelegasikan inferensi ke server jarak jauh (cloud). Hal ini menciptakan empat kegagalan struktural: latensi tak terbatas yang dipengaruhi kondisi jaringan, biaya marjinal per permintaan, ketergantungan mutlak pada konektivitas, dan pengiriman data pengguna keluar dari perangkat. Bersama-sama, hambatan ini mematikan seluruh kategori produk seperti alat inspeksi lapangan, pencatatan klinis di wilayah minim sinyal, penanganan dokumen yang diatur regulasi privasi, dan apa pun yang diharapkan berfungsi di dalam pesawat.

Disiplin rekayasa yang diperlukan untuk menjembatani celah ini tidak sama dengan disiplin untuk memanggil API. Ini menyangkut kesalahan kuantisasi (quantization error), pemuatan bobot berbasis memory-mapped (mmap), pemilihan delegate pada silikon heterogen, isolasi thread pada runtime UI yang single-threaded, dan perhitungan anggaran bingkai (frame budget).

### 1.2 Tesis Produk

> **TESIS:**
> EdgeBench adalah aplikasi Flutter yang berisi tiga subsistem inferensi independen — teks, visi, dan suara — yang masing-masing harus berjalan sepenuhnya di dalam perangkat, secara bersamaan dengan antarmuka pengguna (UI) 60 fps, pada perangkat keras mulai dari ponsel Android murah tahun 2019 hingga iPhone generasi terbaru. Nilai jual aplikasi ini bukanlah apa yang dilakukannya, melainkan laporan tolok ukur (benchmark) yang dihasilkannya sendiri, dan fakta bahwa angka-angka tersebut dapat direproduksi oleh pihak ketiga yang memegang perangkat keras yang sama.

### 1.3 Hal-hal di Luar Target (Non-goals)

Berikut adalah hal-hal yang secara eksplisit berada di luar cakupan. Mengimplementasikannya akan dianggap sebagai pelanggaran cakupan dan cacat produk:

*   **Setiap panggilan jaringan yang berpartisipasi dalam jalur inferensi.** Mengunduh model saat instalasi diizinkan; I/O jaringan saat inferensi dilarang.
*   **Akun pengguna, otentikasi, sinkronisasi, atau komponen sisi server apa pun.**
*   **Pelatihan model (training) atau fine-tuning.** Model dikonsumsi sebagai artefak, dikonversi dan dikuantisasi secara lokal, tidak pernah dilatih.
*   **Keluasan fitur.** Tiga subsistem saja. Tidak ada yang keempat.
*   **Polesan visual (UI)** di luar apa yang diperlukan untuk membuktikan bahwa thread UI tidak terblokir.
*   **Target desktop lintas platform atau web.**

### 1.4 Batasan Anti-Generasi AI

PRD ini dirancang agar model bahasa (LLM) tidak dapat menghasilkan kiriman yang lolos dengan mematok kriteria penerimaan pada pengukuran fisik:

| Apa yang Bisa Dihasilkan LLM | Apa yang Dituntut oleh PRD Ini |
| :--- | :--- |
| Kode integrasi plugin yang tampak masuk akal | Angka latensi p99 yang diukur di 500 pengujian pada 3 perangkat fisik spesifik |
| Pengaturan isolate yang tampak oke | Bukti ekspor timeline trace bahwa tidak ada frame UI melebihi 16.67 ms selama sesi inferensi 90 detik |
| Skrip konversi model | Analisis kesalahan kuantisasi yang membandingkan output referensi FP32 dengan output INT4 pada data uji terpisah, dilaporkan per kelas |
| Diagram arsitektur | Kurva termal yang menunjukkan penurunan throughput selama 15 menit dan mitigasi untuk memulihkannya |
| Penanganan kesalahan generik | Jalur pemulihan OOM (Out of Memory) yang terdokumentasi dan divalidasi dengan memicu tekanan memori secara sengaja pada perangkat 3 GB |

Setiap gerbang di Bagian 5 memerlukan artefak yang hanya bisa ada jika kode tersebut dijalankan pada perangkat keras yang dimiliki secara fisik oleh penulisnya.

### 1.5 Matriks Perangkat Keras Target

Hasil emulator tidak sah untuk gerbang performa apa pun. Engineer harus memiliki akses fisik ke satu perangkat per tier berikut:

*   **Tier C — Lantai (Floor):** Android, RAM 4 GB, sekelas Snapdragon 665 atau setara, API 29. Tidak ada NPU yang dapat digunakan. Harus menggunakan fallback CPU-only. Tier ini menentukan batas atas memori (memory ceiling).
*   **Tier B — Volume (Rata-rata):** Android, RAM 8 GB, Snapdragon seri 7 / sekelas Dimensity 8000, API 33+. Tersedia delegate NNAPI atau GPU. Tier ini menentukan target latensi utama.
*   **Tier A — Atap (Ceiling):** iPhone 13 atau lebih baru, iOS 16+. Apple Neural Engine via Core ML. Tier ini menentukan throughput kasus terbaik dan memvalidasi jalur platform kedua.

> [!WARNING]
> **ATURAN SUBSTITUSI:** Perangkat hanya boleh diganti dengan yang sekelas dalam tier yang sama, dan substitusi tersebut harus dicatat dalam laporan tolok ukur beserta model SoC, RAM, nomor build OS, dan catatan desain termal. Mengganti Tier C dengan perangkat flagship akan membatalkan seluruh kiriman.

---

## 2 · Fitur I — Sovereign LLM Runtime

*   **Nama sandi:** ORACLE
*   **Bobot Evaluasi:** 40%

### 2.1 Deskripsi

Antarmuka teks berbasis percakapan dan Retrieval-Augmented Generation (RAG) yang didukung oleh model bahasa kecil (Small Language Model / SLM) yang berjalan sepenuhnya pada komputasi perangkat sendiri. Model dimuat dari penyimpanan lokal, dikuantisasi ke 4-bit, dieksekusi di background isolate, dan mengalirkan (stream) token ke UI dengan kecepatan yang tidak pernah menyebabkan dropped frame.

Lapisan pencarian (retrieval) mengindeks dokumen yang diimpor pengguna (PDF, teks biasa, markdown) ke dalam penyimpanan vektor lokal, dan menjawab pertanyaan berdasarkan dokumen tersebut. Pembuatan embedding juga dilakukan di dalam perangkat tanpa API eksternal.

### 2.2 Kebutuhan Fungsional

*   **ORC-F1:** Aplikasi dikirimkan tanpa bobot model. Saat pertama kali diluncurkan, aplikasi mengunduh artefak model yang ditandatangani, memverifikasi checksum SHA-256 dengan nilai yang dikompilasi ke dalam binary, dan menyimpannya di penyimpanan privat aplikasi. Ketidakcocokan checksum akan membatalkan instalasi dan memunculkan error spesifik.
*   **ORC-F2:** Bobot model dimuat secara memory-mapped (mmap), bukan dibaca ke dalam Dart heap. Lonjakan RSS (Resident Set Size) akibat pemuatan bobot tidak boleh melebihi 1.15× ukuran artefak di disk.
*   **ORC-F3:** Inferensi dieksekusi dalam background isolate yang berumur panjang (long-lived). Isolate dibuat sekali saat sesi dimulai dan digunakan kembali; pembuatan isolate per permintaan (per-request) dianggap sebagai cacat program.
*   **ORC-F4:** Token mengalir ke UI secara bertahap (incremental). Pengguna melihat token pertama sebelum seluruh respons selesai dibuat.
*   **ORC-F5:** Proses pembuatan teks dapat dibatalkan di tengah jalan. Pembatalan harus mengosongkan cache KV dan mengembalikan runtime ke kondisi diam (idle) dalam waktu 200 ms, diverifikasi dengan pengambilan sampel memori.
*   **ORC-F6:** Pengguna dapat mengimpor dokumen. Setiap dokumen dipotong (chunked), dimasukkan ke embedding di perangkat, dan disimpan dalam indeks vektor lokal. Proses impor dapat dilanjutkan kembali jika aplikasi terhenti atau restart.
*   **ORC-F7:** Pencarian mengembalikan potongan top-k berdasarkan cosine similarity, memasukkannya ke dalam prompt dalam batas anggaran token yang ketat, dan mengutip potongan sumber mana yang menginformasikan jawaban tersebut.
*   **ORC-F8:** Riwayat percakapan dipotong menggunakan sliding window dengan penghitungan token yang eksplisit. Aplikasi tidak boleh membuat prompt yang melebihi batas konteks model; pemotongan senyap (silent truncation) oleh runtime dianggap sebagai cacat program.
*   **ORC-F9:** Panel diagnostik yang terlihat melaporkan secara langsung: token per detik, waktu menuju token pertama (time to first token), ukuran cache KV saat ini dalam byte, delegate yang aktif, dan resident set size (RSS).
*   **ORC-F10:** Jika terjadi kegagalan alokasi memori, runtime akan menurunkan performanya secara anggun (graceful degradation) — mengurangi jendela konteks, mengosongkan cache, mencoba kembali — alih-alih mengalami crash. Jalur degradasi ini harus didokumentasikan dan didemonstrasikan.

### 2.3 Spesifikasi Teknis

#### 2.3.1 Model dan Kuantisasi

*   **Model Dasar:** Model open-weight instruction-tuned dalam kisaran parameter 0.3B–1.5B (Gemma 3 270M/1B, Qwen2.5-0.5B/1.5B-Instruct, atau SmolLM2-1.7B).
*   **Target Kuantisasi:** 4-bit, grouped, dengan lapisan embedding dan output dipertahankan pada presisi yang lebih tinggi. Engineer memilih skema tersebut dan harus membenarkannya terhadap degradasi perplexity yang diukur. Konversi dilakukan secara lokal oleh engineer (bukan mengunduh dari model hub).
*   **Analisis Kuantisasi Wajib:** Evaluasi referensi FP16 dan artefak INT4 pada set terpisah minimal 200 prompt dari benchmark publik. Laporkan perplexity untuk keduanya dan laporkan distribusi divergensi (bukan hanya rata-rata). Jawab secara tertulis: kategori prompt mana yang paling terdegradasi, dan apa implikasinya terhadap batas implementasi model ini? Jawaban "akurasi turun sedikit" dianggap gagal.

#### 2.3.2 Arsitektur Isolate

Batasan paling ketat dalam fitur ini adalah thread UI Dart tidak boleh terblokir. Batasan: tidak ada panggilan FFI sinkron pada main isolate yang boleh melebihi 1 ms. Pemuatan, pembuatan, dan pembongkaran semuanya harus melewati batas port komunikasi antar-isolate.

Panggilan ke native runtime dilakukan melalui `dart:ffi` atau platform channel. Jika menggunakan channel, itu harus berupa background-thread channel — `MethodChannel` standar yang diserialisasikan pada thread platform akan gagal dalam anggaran bingkai UI dan didiskualifikasi. Payload token yang melewati port harus menggunakan `TransferableTypedData` atau transfer zero-copy setara untuk buffer apa pun di atas 4 KB.

#### 2.3.3 Lapisan Pencarian (Retrieval)

*   **Penyimpanan Vektor:** SQLite dengan ekstensi vektor, atau indeks buatan sendiri di atas blob biner. Pilihan harus dijustifikasi terhadap latensi kueri yang diukur pada 10.000 potongan (chunks).
*   **Model Embedding:** Berjalan di perangkat, di isolate yang sama atau bersaudara. Proses embedding PDF 40 halaman tidak boleh membekukan UI.

### 2.4 Gerbang Penerimaan — ORACLE

*(Diukur pada Tier B, merupakan nilai median dari 500 pengujian kecuali dinyatakan lain)*

| Gerbang | Metrik | Ambang Batas |
| :--- | :--- | :--- |
| **ORC-G1** | Waktu menuju token pertama, cold (model sudah ada di memori) | ≤ 900 ms |
| **ORC-G2** | Waktu menuju token pertama, warm | ≤ 350 ms |
| **ORC-G3** | Throughput pembuatan teks berkelanjutan | ≥ 8 tok/s Tier B · ≥ 4 tok/s Tier C · ≥ 20 tok/s Tier A |
| **ORC-G4** | Anggaran bingkai UI selama 90 detik pembuatan kontinu | Nol frame > 16.67 ms. Dibuktikan dengan ekspor timeline trace. |
| **ORC-G5** | Puncak memori residen, Tier C, konteks 2048 token | ≤ 1.4 GB total proses RSS |
| **ORC-G6** | Latensi pembatalan hingga kondisi diam | ≤ 200 ms, memori kembali ke kisaran 5% dari baseline pra-pembuatan |
| **ORC-G7** | Latensi kueri pencarian pada 10.000 potongan terindeks | ≤ 120 ms p95 |
| **ORC-G8** | Akurasi pencarian — potongan sumber benar masuk top-3 | ≥ 85% pada set evaluasi 100 pertanyaan tetap |
| **ORC-G9** | Degradasi perplexity, INT4 vs FP16 | Dilaporkan beserta distribusi (tanpa ambang batas minimun, tapi jika tidak dilaporkan otomatis gagal) |
| **ORC-G10** | Ketahanan termal: throughput menit ke-15 vs menit ke-1 | ≥ 60% dipertahankan, dengan strategi mitigasi yang didokumentasikan |
| **ORC-G11** | Pemulihan OOM pada Tier C di bawah tekanan sengaja | Menurunkan performa tanpa crash dalam 10 dari 10 uji coba |

> [!IMPORTANT]
> **TITIK KEGAGALAN UTAMA:** Pengembang biasanya gagal di ORC-G4. Token yang tiba lebih cepat daripada kemampuan UI untuk membangun ulang, dikombinasikan dengan penggunaan setState pada setiap token, menghasilkan waktu frame 40–90 ms. Teknik pengelompokan (batching), pembatasan frekuensi (throttling) ke sinyal vsync, dan membangun ulang hanya pada node teks daun (leaf text node) adalah tiga teknik untuk menyelesaikannya.

---

## 3 · Fitur II — Real-Time Vision Pipeline

*   **Nama sandi:** APERTURE
*   **Bobot Evaluasi:** 35%

### 3.1 Deskripsi

Alur kamera kontinu yang melakukan deteksi dan ekstraksi terstruktur pada setiap frame yang layak, menampilkan hamparan (overlay) hasil dalam registrasi spasial dan temporal yang sempurna dengan pratinjau langsung (live preview), tanpa menurunkan pratinjau di bawah 30 fps pada tier terendah (Tier C).

Domain yang dipilih adalah pembacaan terstruktur dari dunia fisik: jarum/angka meteran analog dan digital, panel nutrisi cetak, atau pelat nomor seri. Fokusnya bukan klasifikasi gambar statis, melainkan ekstraksi nilai yang benar beserta estimasi tingkat keyakinan (confidence) dari gambar yang bergerak, minim cahaya, dan terhalang sebagian.

### 3.2 Mengapa Ini Lebih Sulit daripada Kelihatannya

Alur waktu nyata (real-time pipeline) memperkenalkan tiga batasan yang saling terkait:

1.  **Kamera menghasilkan frame lebih cepat daripada konsumsi model:** Menyebabkan pertumbuhan antrean tak terbatas, kehabisan memori, dan lag overlay yang terus bertambah hingga aplikasi tidak dapat digunakan.
2.  **Latensi inferensi bervariasi, namun pratinjau tidak:** Kotak pembatas (bounding box) merujuk pada frame yang salah. Overlay tertinggal di belakang objek fisik.
3.  **Frame tiba dalam format native platform (YUV420 di Android, BGRA di iOS):** Konversi naif dalam Dart memakan biaya 20–40 ms per frame dan langsung menghabiskan anggaran waktu bingkai UI.

### 3.3 Kebutuhan Fungsional

*   **APR-F1:** Aliran kamera dikonsumsi dengan tekanan balik (backpressure) yang eksplisit. Saat inferensi sibuk, frame masuk berikutnya dibuang — tidak pernah diantrekan. Maksimum frame yang diproses dalam satu waktu adalah tepat satu.
*   **APR-F2:** Setiap frame yang dikirim ke model membawa stempel waktu (timestamp) monoton. Setiap overlay membawa stempel waktu dari frame asalnya. Renderer harus menyelaraskan keduanya.
*   **APR-F3:** Konversi YUV-ke-RGB dan penyiapan tensor terjadi di luar thread UI, dalam kode native atau dalam worker isolate. Loop per-piksel dalam Dart pada main isolate dilarang.
*   **APR-F4:** Alur memilih hardware delegate saat runtime (NNAPI, GPU, atau Core ML), mengujinya, memvalidasi output terhadap referensi CPU, dan secara senyap mundur (fallback) ke CPU jika gagal. Pemilihan ini dicatat dalam log dan dimunculkan di diagnostik.
*   **APR-F5:** Hasil deteksi dihaluskan secara temporal lintas frame untuk mencegah efek berkedip (flicker) akibat false positive satu frame.
*   **APR-F6:** Setiap ekstraksi membawa nilai keyakinan (confidence value) yang terkalibrasi. Di bawah ambang batas yang didokumentasikan, UI harus menunjukkan ketidakpastian daripada menegaskan nilai yang salah.
*   **APR-F7:** Overlay harus tetap presisi di bawah rotasi perangkat, perbedaan orientasi sensor, dan efek kotak surat (letterboxing) rasio aspek pratinjau.
*   **APR-F8:** Hamparan diagnostik melaporkan: fps pratinjau, fps inferensi, frame dibuang per detik, latensi ujung-ke-ujung (end-to-end), delegate aktif, dan kondisi termal saat ini.
*   **APR-F9:** Ketika perangkat memasuki perlambatan termal (thermal throttling), alur mengurangi frekuensi inferensi dan mengomunikasikannya kepada pengguna alih-alih tersendat secara senyap.
*   **APR-F10:** Semua buffer kamera dilepaskan secara eksplisit. Sesi 10 menit tidak boleh menunjukkan pertumbuhan memori monoton.

### 3.4 Arsitektur Pipeline dan Anggaran Latensi (Tier B Per Frame)

*   **Akuisisi + Konversi:** ≤ 8 ms (Native YUV→RGB, pemotongan ukuran + normalisasi, zero-copy jika didukung platform)
*   **Inferensi:** ≤ 22 ms (delegate.run(tensor))
*   **Pascaproses:** ≤ 5 ms (NMS + dekode, penghalusan temporal, kalibrasi keyakinan)
*   **Pengecatan UI:** ≤ 3 ms (CustomPainter — HANYA mengecat ulang lapisan overlay. Tekstur pratinjau kamera tidak pernah dibangun ulang)
*   **Total Ujung-ke-Ujung:** ≤ 38 ms (≈26 fps inferensi). Thread pratinjau tidak terpengaruh, tetap minimal 30 fps.

### 3.5 Kebutuhan Model

*   Menggunakan arsitektur deteksi efisien seluler (MobileNet-SSD, YOLO-nano, atau setara).
*   Model harus dikuantisasi ke INT8 dengan dataset kalibrasi representatif yang disusun oleh engineer. Kuantisasi rentang dinamis pasca-pelatihan (post-training dynamic-range quantization) tanpa dataset kalibrasi tidak diperbolehkan.
*   Perbandingan akurasi per kelas antara model FP32 dan INT8 adalah wajib untuk mengidentifikasi kelas mana yang rusak akibat kuantisasi.

### 3.6 Gerbang Penerimaan — APERTURE

| Gerbang | Metrik | Ambang Batas |
| :--- | :--- | :--- |
| **APR-G1** | Frame rate pratinjau selama inferensi kontinu | ≥ 30 fps Tier C · ≥ 55 fps Tier B · ≥ 55 fps Tier A |
| **APR-G2** | Latensi ujung-ke-ujung, tangkapan frame hingga cat overlay | ≤ 60 ms p95 Tier B · ≤ 120 ms p95 Tier C |
| **APR-G3** | Kesalahan registrasi temporal overlay | ≤ 1 frame pergeseran (drift), dibuktikan dengan rekaman video kecepatan tinggi |
| **APR-G4** | Akurasi ekstraksi pada set evaluasi terkontrol (≥300 gambar berlabel, ≥20% adversarial: silau, kabur, miring, terhalang) | ≥ 92% kecocokan tepat pada subset bersih · ≥ 70% pada subset adversarial |
| **APR-G5** | Tingkat pernyataan salah — output salah dengan keyakinan tinggi di atas ambang batas | ≤ 2%. Ini adalah gerbang akurasi terpenting. Diam lebih baik daripada memberikan angka yang salah. |
| **APR-G6** | Kalibrasi tingkat keyakinan | Kesalahan Kalibrasi yang Diharapkan (Expected Calibration Error) ≤ 0.10, dengan diagram keandalan disertakan |
| **APR-G7** | Stabilitas memori selama sesi kontinu 10 menit | Variasi RSS dari puncak-ke-puncak ≤ 8%, nol pertumbuhan monoton |
| **APR-G8** | Perilaku termal selama 15 menit kontinu | Fps inferensi berkelanjutan di menit ke-15 ≥ 50% dari menit ke-1 |
| **APR-G9** | Kebenaran fallback delegate | Kegagalan paksa pada delegate utama menghasilkan output benar pada CPU dalam waktu 2 detik, tanpa crash, 10 dari 10 uji coba |
| **APR-G10** | Registrasi orientasi dan letterbox | Penyelarasan overlay yang benar di keempat orientasi pada kedua platform |

> [!CAUTION]
> **GERBANG PEMBEDA:** Gerbang APR-G5 memisahkan engineer sejati dari sekadar integrator. Sistem harus tahu kapan ia tidak tahu. Pemuatan sistem yang melaporkan keyakinan 99% pada meteran kabur yang salah baca akan otomatis GAGAL.

---

## 4 · Fitur III — Offline Speech Command Engine

*   **Nama sandi:** ECHO
*   **Bobot Evaluasi:** 25%

### 4.1 Deskripsi

Penangkapan mikrofon terus-menerus, pengenalan suara di dalam perangkat (on-device speech recognition), dan pemetaan deterministik dari ucapan yang ditranskripsikan ke tindakan aplikasi yang terstruktur — dengan nol keterlibatan jaringan dan latensi jam dinding (wall-clock latency) yang sangat rendah dari akhir ucapan hingga eksekusi tindakan.

Fitur ini memaksa engineer menyeberangi batas FFI. Engineer akan mengompilasi kode native untuk dua platform, menautkannya (linking), mengelola memorinya secara manual dari Dart, dan menangani mode kegagalannya.

### 4.2 Kebutuhan Fungsional

*   **ECH-F1:** Audio ditangkap sebagai aliran kontinu pada sample rate asli model. Pembuatan sampel ulang (resampling), jika diperlukan, dilakukan dalam kode native, bukan di Dart.
*   **ECH-F2:** Deteksi Aktivitas Suara (Voice Activity Detection / VAD) menyaring pengenal suara. Keheningan tidak boleh ditranskripsikan dan tidak boleh memakan daya komputasi. VAD berjalan terus-menerus dengan biaya komputasi yang sangat kecil.
*   **ECH-F3:** Mesin pengenal dipanggil melalui `dart:ffi` terhadap pustaka (library) yang dikompilasi secara native. Build harus dapat direproduksi dari sumber pada kedua platform melalui rantai alat (toolchain) skrip yang didokumentasikan.
*   **ECH-F4:** Semua memori native yang dialokasikan di seluruh batas FFI dilepaskan secara eksplisit. Diperlukan penggunaan `NativeFinalizer` atau disiplin kepemilikan deterministik yang setara. Kebocoran memori (leak) adalah cacat program tidak peduli seberapa lambat akumulasinya.
*   **ECH-F5:** Hasil transkripsi parsial mengalir ke UI selama ucapan berlangsung. Pengguna melihat teks terbentuk sebelum mereka selesai berbicara.
*   **ECH-F6:** Teks yang ditranskripsikan dipetakan ke tata bahasa tindakan (action grammar) terbatas yang ditentukan oleh engineer — minimal 15 intent berbeda dengan ekstraksi slot (misalnya jumlah numerik, tanggal, dan entitas bernama).
*   **ECH-F7:** Resolusi intent harus menangani kesalahan pengenalan. Transkripsi yang hampir cocok harus diselesaikan ke intent yang benar melalui pencocokan fonetik atau edit-distance, dan input yang tidak dapat diselesaikan harus ditolak secara eksplisit alih-alih dipetakan ke tindakan salah yang tampak masuk akal.
*   **ECH-F8:** Mesin beroperasi saat perangkat offline dalam arti yang paling kuat: mode pesawat (airplane mode) diaktifkan, diverifikasi selama pengujian penerimaan.
*   **ECH-F9:** Siklus hidup sesi audio ditangani dengan benar di kedua platform — interupsi oleh panggilan masuk, perubahan rute ke Bluetooth, dan transisi ke latar belakang semuanya pulih tanpa perlu restart.
*   **ECH-F10:** Diagnostik melaporkan: faktor waktu nyata (real-time factor), kondisi VAD, waktu muat model, heap native yang disebabkan oleh pengenal suara, dan perincian latensi per ucapan.

### 4.3 Spesifikasi Teknis

#### 4.3.1 Mesin Pengenal (ASR Engine)

Menggunakan Whisper.cpp, sherpa-onnx, atau runtime ASR offline setara yang dikompilasi. API ucapan bawaan platform (seperti iOS SFSpeechRecognizer atau Android SpeechRecognizer) dilarang karena berpotensi merutekan data ke server. Pustaka harus dibangun dari kode sumber untuk arsitektur arm64-v8a, armeabi-v7a, dan iOS arm64. Binary pra-built (prebuilt binaries) yang tidak diketahui asal-usulnya tidak dapat diterima.

#### 4.3.2 Kontrak Batas FFI (Aturan Kepemilikan)

1.  Dart mengalokasikan buffer audio. Dart membebaskannya.
2.  Native mengalokasikan struct hasil. Native membebaskannya, dipanggil dari Dart melalui simbol rilis eksplisit yang diikat ke `NativeFinalizer`.
3.  Tidak ada objek Dart yang menyimpan Pointer mentah melebihi masa pakai isolate yang membuatnya.
4.  Setiap panggilan native yang dapat gagal harus mengembalikan kode status. Pengembalian pointer yang dapat bernilai null (nullable pointer) dilarang sebagai satu-satunya sinyal kesalahan.

> **Batasan Utas (Threading):** Pengenal berjalan di isolate-nya sendiri dengan konteks native-nya sendiri. Dua isolate tidak boleh berbagi satu handle pengenal suara yang sama.

### 4.4 Gerbang Penerimaan — ECHO

| Gerbang | Metrik | Ambang Batas |
| :--- | :--- | :--- |
| **ECH-G1** | Faktor waktu nyata (durasi audio ÷ durasi pemrosesan) | ≤ 0.45 Tier B · ≤ 0.80 Tier C · ≤ 0.25 Tier A |
| **ECH-G2** | Akhir ucapan hingga tindakan dieksekusi | ≤ 700 ms p95 Tier B · ≤ 1400 ms p95 Tier C |
| **ECH-G3** | Word Error Rate (WER) pada set evaluasi (≥200 ucapan, ≥3 pembicara, ≥2 kondisi kebisingan) | ≤ 15% bersih · ≤ 30% pada SNR sekitar 10 dB |
| **ECH-G4** | Akurasi resolusi intent dengan transkripsi yang benar | ≥ 97% |
| **ECH-G5** | Akurasi resolusi intent dengan transkripsi yang mengandung kesalahan ASR | ≥ 85% (mengukur ketahanan lapisan pencocokan) |
| **ECH-G6** | Tingkat tindakan salah pada input di luar tata bahasa (out-of-grammar) | ≤ 3%. Penolakan adalah perilaku yang benar. |
| **ECH-G7** | Pertumbuhan heap native selama 200 ucapan berturut-turut | ≤ 2 MB total. Diukur dengan native memory profiler. |
| **ECH-G8** | Responsivitas UI selama pengenalan suara | Nol frame > 16.67 ms, terverifikasi lewat trace |
| **ECH-G9** | Operasi mode pesawat | Fungsionalitas penuh |
| **ECH-G10** | Pemulihan interupsi audio | Pemulihan benar dari panggilan masuk, Bluetooth, latar belakang (5 dari 5 uji coba) |

> [!WARNING]
> **TITIK KEGAGALAN UTAMA:** Kebocoran memori native di seluruh batas FFI (ECH-G7) tidak mengumumkan dirinya sendiri. Angka 200 ucapan sengaja dipilih agar kebocoran beberapa kilobyte per ucapan menjadi terlihat jelas dalam satu sesi profiler.

---

## 5 · Spesifikasi Desain

### 5.1 Prinsip Desain

Antarmuka dibuat untuk membuktikan rekayasa teknis, bukan untuk dekorasi visual. Bahasa visual yang digunakan adalah instrumentasi (seperti dasbor indikator pesawat): permukaan gelap, angka monospasi untuk semua telemetri, dan satu warna aksen yang digunakan eksklusif untuk status yang memerlukan perhatian. UI yang rumit meningkatkan biaya render per frame dan membuat gerbang performa lebih sulit ditembus.

### 5.2 Token Desain (Ringkasan Warna & Tipografi)

*   `surface.base`: `#0B1220` (Latar belakang aplikasi)
*   `surface.raised`: `#141C2E` (Kartu, panel, lembar dokumen)
*   `surface.overlay`: `#1C2740` (Laci diagnostik, modal)
*   `accent.action`: `#F97316` (Status inferensi aktif, tindakan utama)
*   `state.good` / `warn` / `fail`: `#34D399` / `#FBBF24` / `#F87171`
*   `type.ui`: Font **Inter** (Untuk semua teks antarmuka)
*   `type.mono`: Font **JetBrains Mono** (Wajib tanpa pengecualian untuk semua telemetri numerik)

### 5.3 Arsitektur Informasi & Spesifikasi Permukaan

Bilah telemetri harus ada di setiap permukaan di bagian atas dan dapat diperluas menjadi laci diagnostik lengkap. Ini bukan mode debug; ini adalah produk itu sendiri.

*   **ORACLE (Percakapan):** Daftar pesan menggunakan builder yang mendaur ulang item di luar layar (lazy list). Aliran token hanya memperbarui satu node teks daun tunggal. Pengukur anggaran konteks menunjukkan token yang dikonsumsi, berubah menjadi `warn` pada 80% dan `fail` pada 95%. Tombol batalkan respons aktif selama pembuatan teks dan merespons dalam 1 frame setelah ditekan.
*   **APERTURE (Kamera):** Pratinjau kamera full-bleed. Warna garis kotak deteksi mengodekan keyakinan secara langsung. Kluster instrumen di sudut menunjukkan fps pratinjau, fps inferensi, tingkat pembuangan frame, dan latensi ujung-ke-ujung dalam font monospasi. Nilai yang diekstraksi berkumpul di lembar bawah (bottom sheet) lengkap dengan cuplikan gambar dan stempel waktu frame asalnya untuk kebutuhan audit.
*   **ECHO (Suara):** Visualisasi bentuk gelombang (waveform) yang didorong oleh isyarat VAD, bukan amplitudo mentah. Intent yang berhasil diselesaikan dan slot ekstraksinya ditampilkan sebagai kartu terstruktur sebelum tindakan dieksekusi. Perincian latensi per ucapan tersedia di laci diagnostik.
*   **BENCH (Tolok Ukur):** Permukaan ini menjalankan uji penerimaan pada perangkat secara otomatis dan harus diimplementasikan sebelum fitur ketiga selesai. Membangunnya di akhir berarti fitur-fitur sebelumnya dikembangkan tanpa pengukuran. Halaman ini menangkap sidik jari perangkat (SoC, RAM, OS, akselerator) dan mengekspor artefak JSON yang ditandatangani serta laporan yang dapat dibaca manusia.

### 5.5 Batasan Antarmuka yang Tidak Dapat Dinegosiasikan

1.  **Dilarang menggunakan `setState` di atas node daun pada jalur streaming:** Biaya bangun ulang widget (widget rebuild) adalah penyebab dominan kegagalan anggaran bingkai UI.
2.  **Semua angka telemetri menggunakan font monospasi dengan lebar tetap:** Digit proporsional menyebabkan tata letak berubah (layout reflow) pada setiap pembaruan, yang lambat dan tidak rapi.
3.  **Tidak ada animasi yang mengalokasikan memori selama callback bingkainya:** Alokasi pada jalur bingkai memicu jeda Garbage Collection (GC) yang muncul sebagai dropped frame.
4.  **Setiap operasi panjang harus dapat dibatalkan.** Tingkat keyakinan harus selalu terlihat oleh pengguna.

---

## 6 · Laporan Tolok Ukur (Benchmark Report)

Laporan adalah deliverable utama. Aplikasi hanyalah instrumen yang memproduksinya.

### 6.1 Isi yang Diperlukan

*   Sidik jari perangkat untuk ketiga tier (SoC, konfigurasi core, RAM, nomor build OS, akselerator yang tersedia, dan kondisi lingkungan sekitar saat pengukuran).
*   Setiap gerbang dari Bagian 2, 3, dan 4 dilaporkan dengan nilai terukur, ambang batas, dan keputusan lolos/gagal.
*   Distribusi latensi dilaporkan sebagai p50, p95, dan p99 — tidak boleh berupa nilai rata-rata (mean) saja.
*   Profil memori: Puncak RSS, heap native, dan heap Dart, disampel sepanjang sesi.
*   Kurva termal untuk ORACLE dan APERTURE di bawah beban berkelanjutan selama 15 menit.
*   Analisis kesalahan kuantisasi untuk model bahasa dan visi dengan tingkat degradasi per kategori.
*   Hasil akurasi dengan confusion matrix untuk output klasifikasi dan diagram keandalan untuk nilai keyakinan.
*   Konsumsi baterai per 10 menit inferensi berkelanjutan.
*   Dekomposisi ukuran berkas APK dan IPA (kontribusi setiap pustaka native dan artefak model).

### 6.2 Narasi Rekayasa (Pertanyaan Wajib)

Angka tanpa penalaran bukanlah bukti rekayasa. Laporan harus memuat bagian tertulis yang menjawab pertanyaan-pertanyaan berikut secara jujur:

1.  Gerbang mana yang paling sulit diloloskan, dan apa perubahan spesifik (sebutkan kode komitmen/ commit) yang berhasil meloloskannya?
2.  Gerbang mana yang pertama kali gagal, dan apa yang ditunjukkan oleh profiler yang bertentangan dengan intuisi Anda?
3.  Apa yang Anda ukur yang membuat Anda terkejut? Laporan tanpa kejutan menandakan Anda kurang mengukur.
4.  Di mana aplikasi ini gagal? Sebutkan perangkat, kondisi, atau kelas input tempat ia mengalami degradasi, dan nyatakan mengapa Anda menerima batasan tersebut alih-alih memperbaikinya.
5.  Apa yang akan Anda bangun ulang jika Anda memulai dari awal lagi, dan apa filosofi di balik keputusan tersebut?

### 6.3 Persyaratan Reproduksibilitas

*   Rangkaian tolok ukur (benchmark suite) harus dapat dijalankan oleh pihak ketiga dengan satu perintah terhadap perangkat yang mereka miliki.
*   Konversi dan kuantisasi model harus dapat direproduksi dari alur skrip yang dimasukkan ke repositori.
*   Build pustaka native untuk kedua platform harus menggunakan skrip dan berhasil dijalankan dari keadaan repositori yang bersih (clean checkout).

---

## 7 · Produk Serahan (Deliverables) dan Evaluasi

### 7.1 Inventaris Produk Serahan

*   **D1 (Repositori Sumber):** Kompilasi bersih di kedua platform. Tidak ada rahasia (secrets) atau binary dari sumber tak dikenal yang dimasukkan ke git.
*   **D2 (Artefak Rilis yang Ditandatangani):** Android AAB dan iOS IPA yang dapat diinstal, lengkap dengan dokumentasi dekomposisi ukuran berkas.
*   **D3 (Laporan Tolok Ukur):** Seluruh konten Bagian 6 dalam format tahan lama, dilampiri ekspor JSON mentah.
*   **D4 (Alur Kerja Model):** Skrip konversi, kuantisasi, dan kalibrasi yang dapat direproduksi dari keadaan bersih.
*   **D5 (Skrip Build Native):** Skrip untuk kedua platform dengan versi toolchain yang terdokumentasi.
*   **D6 (Dataset Evaluasi):** Set berlabel milik engineer sendiri untuk ekstraksi visi, pertanyaan pencarian, dan ucapan suara beserta metode pelabelannya.
*   **D7 (Dokumen Arsitektur):** Topologi isolate, model kepemilikan memori, kontrak FFI, dan disiplin threading lengkap dengan diagram.
*   **D8 (Jalur Rekaman Timeline):** Trace Flutter DevTools yang diekspor untuk membuktikan kepatuhan anggaran bingkai UI pada fitur ORACLE, APERTURE, dan ECHO.
*   **D9 (Integrasi Berkelanjutan / CI):** Membangun aplikasi di kedua platform, menjalankan rangkaian pengujian, dan menghasilkan artefak pada penandaan versi (tag).
*   **D10 (Rekaman Demonstrasi):** Rekaman video satu kali ambil tanpa jeda/potongan (single-take, no cuts), mode pesawat terlihat jelas diaktifkan, menunjukkan tiga fitur utama dan permukaan tolok ukur berfungsi.

### 7.2 Bobot Evaluasi

*   **Gerbang Performa Terpenuhi (35%):** Apakah angka-angka itu nyata dan melampaui ambang batas.
*   **Akurasi dan Kalibrasi (30%):** Kebenaran di bawah input adversarial dan apakah sistem tahu saat dirinya salah.
*   **Rigiditas Rekayasa (20%):** Disiplin memori, kebenaran threading, jalur kesalahan, dan kepemilikan sumber daya.
*   **Kualitas Laporan (15%):** Kehadiran penalaran di balik angka-angka dan argumentasi yang kuat.
*   **Jumlah Fitur (0%):** Secara eksplisit tidak diberi bobot. Fitur keempat tidak menghasilkan nilai apa pun.
*   **Polesan Visual (0%):** Tidak diberi bobot di luar batasan esensial pada Bagian 5.5.

### 7.3 Diskualifikasi Otomatis

Hal-hal berikut akan membatalkan seluruh kiriman tanpa melihat hasil lainnya:

*   Adanya permintaan jaringan dalam jalur inferensi yang ditemukan melalui inspeksi lalu lintas data selama penerimaan.
*   Angka performa diukur pada emulator namun disajikan sebagai pengukuran perangkat fisik.
*   Sebuah gerbang dilaporkan lolos namun metode pengukurannya tidak dapat direproduksi oleh penguji.
*   Bobot model atau binary native dimasukkan ke repositori tanpa asal-usul dan jalur build yang terdokumentasi.
*   Rekaman demonstrasi berisi potongan/editan (cuts) selama operasi inferensi berlangsung.

### 7.4 Jadwal Eksekusi

*   **Fase 0 — Instrumentasi (1 minggu):** Permukaan BENCH dibuat dan mengukur waktu frame serta memori sebelum fitur apa pun dibangun. Fase ini wajib di awal.
*   **Fase 1 — ORACLE (3–4 minggu):** Semua gerbang ORC diukur. G4 dan G5 lolos pada Tier C.
*   **Fase 2 — APERTURE (3–4 minggu):** Semua gerbang APR diukur. G5 lolos (tingkat pernyataan salah adalah yang tersulit).
*   **Fase 3 — ECHO (2–3 minggu):** Semua gerbang ECH diukur. G7 lolos dalam uji coba penuh 200 ucapan.
*   **Fase 4 — Penyelarasan / Tuning (1–2 minggu):** Setiap gerbang yang gagal diperbaiki agar lolos atau didokumentasikan sebagai batasan yang diterima beserta alasannya.
*   **Fase 5 — Laporan (1 minggu):** Bagian 6 selesai termasuk jawaban naratif, dan pihak ketiga telah mereproduksi minimal satu gerbang.

---

### Catatan Penutup untuk Engineer

Tiga fitur dalam dokumen ini dipilih karena masing-masing gagal dengan cara yang berbeda, dan tidak ada kegagalan yang terlihat dalam kode sumber. ORACLE gagal pada frame trace. APERTURE gagal pada gambar adversarial yang mengharuskan Anda keluar ruangan untuk mengambilnya. ECHO gagal pada native memory profiler setelah dua ratus ucapan. Anda bisa menyuruh model AI (LLM) menulis sebagian besar kode ini. Tetapi Anda tidak bisa menyuruh AI untuk memegang ponselnya.
