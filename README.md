# Laporan Akhir Proyek Data Warehouse Industri Farmasi  
**Kelompok 16 – Pergudangan Data – 2025**  
Program Studi Sains Data, Institut Teknologi Sumatera  

---

## 1. Ringkasan Proyek dan Latar Belakang  
Industri farmasi dan jaringan apotek menghadapi tantangan dalam mengelola data transaksi yang besar dan tersebar. Untuk mendukung pengambilan keputusan operasional dan strategis yang tepat, dibutuhkan sistem **Data Warehouse (DW)** yang terintegrasi.

Proyek ini bertujuan membangun DW berbasis **star schema** untuk mengintegrasikan data transaksi dari 15 cabang apotek. Sistem ini mendukung analisis produk terlaris, prediksi restok, dan tren penjualan. Dataset berasal dari Kaggle dan diimplementasikan menggunakan **SQL Server 2019**.

---

## 2. Tujuan dan Ruang Lingkup  

### Tujuan:
- Merancang dan membangun arsitektur DW industri farmasi  
- Mengimplementasikan proses ETL dan query analitik berbasis OLAP  
- Menyediakan sistem pendukung keputusan bagi stakeholder  

### Ruang Lingkup:
- Data transaksi penjualan apotek (CSV, 141.400 baris, periode Jan–Des 2024)  
- Skema DW: 1 tabel fakta dan 3 tabel dimensi  
- Visualisasi opsional dengan Power BI  

---

## 3. Metodologi  

### Pendekatan:  
Model pengembangan **Waterfall**, dibagi menjadi empat misi:

| Misi | Aktivitas                                                                 |
|------|--------------------------------------------------------------------------|
| 1    | Analisis kebutuhan dan identifikasi stakeholder                          |
| 2    | Desain konseptual & logikal: Star schema, ERD                            |
| 3    | Desain fisik: indexing, partisi, struktur penyimpanan                    |
| 4    | Implementasi database, ETL, query analitik, dan visualisasi              |

### Tools:
- SQL Server Management Studio (SSMS)  
- Tableu (opsional)  
- Microsoft Excel  
- GitHub  

---

## 4. Analisis Kebutuhan 

| Stakeholder      | Kebutuhan Data                                               |
|------------------|--------------------------------------------------------------|
| Manajer Apotek   | Laporan penjualan, produk unggulan, stok terkini            |
| Tim Inventory    | Prediksi kebutuhan restok berdasarkan pola pembelian         |
| Tim Promosi      | Produk terlaris, jenis sediaan yang populer                  |
| Analis Data      | Tren transaksi harian, bulanan, musiman                      |

📌 **Dataset**: 141.400 baris transaksi dari 15 apotek di Irak (2024)

---

## 5. Desain DW  

### 📐 Konseptual (Star Schema)
- **Fact_Sales**: Sales_Sheet, Sales_Pack, Barcode, Invoice, AddedDate  
- **Dim_Produk**: Barcode, Name, Dosage_Form, Type, Sheet  
- **Dim_Waktu**: AddedDate, Time, Hari, Bulan, Tahun  
- **Dim_Transaksi**: Invoice  

### Logikal
- Relasi Foreign Key antar tabel  
- Metadata tambahan: `CreatedAt`, `IsActive`  

### Fisik
- **Indexing**:
  - Clustered Columnstore Index pada `Fact_Sales`
  - Non-clustered index pada `Dim_Produk`, `Dim_Waktu`
- **Storage**:
  - Partisi waktu berdasarkan `AddedDate` (opsional)
  - Filegroup khusus untuk tabel fakta  

---

## 6. Proses Implementasi   

### ETL
- **Ekstraksi**: Load data CSV ke staging  
- **Transformasi**: Format tanggal (`AddedDate`), jam (`Time`)  
- **Loading**: Masukkan data ke tabel `Dim_*`, lalu ke `Fact_Sales`  

### Script SQL
- `create_tables.sql`: Skema tabel  
- `insert_data.sql`: ETL dan dummy data  
- `analysis_queries.sql`: Query analitik  

### Screenshots 
- **Load data CSV**:
  ![image alt](https://github.com/sains-data/Perancangan-Data-Warehouse-Pada-Industri-Farmasi-dan-Obat---Obatan/blob/cfc6ca93abfbadeb51d96bcf4257542d2d38c1eb/images/MEemasukkan%20Data.jpg)
  
- **Proses ETL**:
  ![image alt](https://github.com/sains-data/Perancangan-Data-Warehouse-Pada-Industri-Farmasi-dan-Obat---Obatan/blob/cfc6ca93abfbadeb51d96bcf4257542d2d38c1eb/images/Proses%20ETL.jpg)

- **Total Penjualan Bulanan**:
  
  ![image alt](https://github.com/sains-data/Perancangan-Data-Warehouse-Pada-Industri-Farmasi-dan-Obat---Obatan/blob/cfc6ca93abfbadeb51d96bcf4257542d2d38c1eb/images/Total%20Penjualan%20Bulanan.jpg)


  
- **Rata-Rata Transaksi Bulanan**:
  
  ![image alt](https://github.com/sains-data/Perancangan-Data-Warehouse-Pada-Industri-Farmasi-dan-Obat---Obatan/blob/cfc6ca93abfbadeb51d96bcf4257542d2d38c1eb/images/Rata-Rata%20Transaksi%20Bulanan.jpg)



- **Produk Terlaris**:
  
  ![image alt](https://github.com/sains-data/Perancangan-Data-Warehouse-Pada-Industri-Farmasi-dan-Obat---Obatan/blob/cfc6ca93abfbadeb51d96bcf4257542d2d38c1eb/images/Produk%20Terlaris.jpg)


- **Pertumbuhan Penjualan Tahunan**:
  
  ![image alt](https://github.com/sains-data/Perancangan-Data-Warehouse-Pada-Industri-Farmasi-dan-Obat---Obatan/blob/cfc6ca93abfbadeb51d96bcf4257542d2d38c1eb/images/Pertumbuhann%20Penjualan%20Tahunan.jpg)
  
---


## 7. Hasil Implementasi

### Tampilan Sistem:
-Database PharmacyDW muncul di Object Explorer SSMS.

-Tabel Dim_Produk, Dim_Waktu, Dim_Transaksi, dan Fact_Sales tersedia di folder Tables.

-Filegroup DW_FactGroup dapat diakses melalui Properties database.

### Fungsionalitas Sistem:
-Sistem mendukung analisis penjualan berdasarkan dimensi produk, waktu, dan transaksi.

-Kinerja kueri analitik cepat berkat penggunaan indeks dan partisi yang tepat.

-Data dummy disiapkan untuk simulasi analisis penjualan secara sederhana.

### Struktur Data:
- **Dim_Produk**: Berisi 5 produk: Paracetamol, Amoxicillin, Hand Sanitizer, Vitamin C, dan Masker Medis.
- **Dim_Waktu**: Memuat 5 entri tanggal antara tahun 2024 hingga 2025.
- **Dim_Transaksi**: Terdiri dari 5 transaksi dengan ID dari INV001 hingga INV005.
- **Fact_Sales**: Memuat 5 baris data transaksi penjualan.

### Deskripsi Tampilan:
- **Object Explorer**: Menampilkan folder Databases dengan database PharmacyDW dan subfolder Tables berisi tabel-tabel yang sudah dibuat.
- **Tab Query**: Menampilkan tab New Query yang memuat skrip create_tables.sql yang sudah dijalankan.
- **Tab Results**: Menampilkan hasil Query 1 berupa tabel total penjualan per bulan dengan kolom Month, Year, dan Total_Penjualan.

---
## 8. Evaluasi

### Keberhasilan:
-Database dan tabel berhasil dibuat sesuai rancangan.

-Proses ETL berjalan dan mengisi data dengan benar.

-Kueri analitik berjalan lancar dan menghasilkan output sesuai ekspektasi.

-Indeks dan partisi meningkatkan performa kueri.

### Kendala Teknis:
-Data tidak terbaca di OLAP SQL Server, kemungkinan kesalahan pada proses insert data.

### Aspek yang Belum Tercapai:
-ETL belum menggunakan SSIS karena keterbatasan sumber data.

-Kueri seperti rata-rata transaksi per pelanggan dan produk terlaris per wilayah belum bisa dijalankan karena dimensi pelanggan dan wilayah belum tersedia.

---

## 9. Rencana Pengembangan

Berikut rencana pengembangan lanjutan sistem Data Warehouse:

- 📍 Menambahkan tabel dimensi baru: `Dim_Lokasi` untuk analisis cabang apotek
- 🔁 Menggunakan **SSIS** (SQL Server Integration Services) untuk proses ETL otomatis
- 📊 Integrasi dengan dashboard online dan pelaporan berbasis mobile
- 🌐 Menyediakan REST API untuk akses frontend dan integrasi sistem lainnya

---

## 10. 👥Tim Proyek – Kelompok 16

| Nama                      | NIM         | Peran                    |
|---------------------------|-------------|---------------------------|
| PANDRA INSANI PUTRA A.    | 121450137   | Implementasi SQL          |
| NABIILAH PUTRI K.         | 122450029   | Analisis kebutuhan        |
| CINTYA BELLA              | 122450066   | Visualisasi & UI          |
| Kayla Amanda Sukma        | 122450086   | Dokumentasi & GitHub      |
| Smertniki Javid A         | 122450115   | Database Design           |
| PARDI OCTAVIANDO          | 122450132   | Project Lead              |

---

> Dokumentasi ini dibuat untuk memenuhi tugas akhir mata kuliah **Pergudangan Data 2025**  
> Institut Teknologi Sumatera – Program Studi Sains Data

