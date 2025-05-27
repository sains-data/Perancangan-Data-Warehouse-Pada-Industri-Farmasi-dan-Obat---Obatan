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

---
## 8. Evaluasi

---

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

