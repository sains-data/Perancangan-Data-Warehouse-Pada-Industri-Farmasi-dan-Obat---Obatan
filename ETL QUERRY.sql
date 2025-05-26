-- ===================================================================
-- PROSES ETL (EXTRACT, TRANSFORM, LOAD)
-- ===================================================================

--- MEMULAI PROSES TRANSFORMASI DAN LOAD
--- Proses ini hanya akan berjalan jika BULK INSERT sebelumnya berhasil
PRINT 'Langkah 3: Memuat data ke tabel dimensi...';

-- ===================================================================
-- LOAD DATA KE DIMENSI TRANSAKSI
-- ===================================================================

--- MEMUAT DATA KE DIM_TRANSAKSI
--- Mengambil nilai Invoice yang unik dari Temp_Sales
--- Hanya memasukkan Invoice yang belum ada di Dim_Transaksi
PRINT 'Memuat data ke Dim_Transaksi...';

INSERT INTO Dim_Transaksi (Invoice)
SELECT DISTINCT TS.Invoice        --- Mengambil Invoice yang unik
FROM Temp_Sales TS
LEFT JOIN Dim_Transaksi DT ON TS.Invoice = DT.Invoice    --- Cek apakah sudah ada
WHERE DT.Invoice IS NULL          --- Hanya yang belum ada
  AND TS.Invoice IS NOT NULL      --- Invoice tidak boleh NULL
  AND TS.Invoice <> '';           --- Invoice tidak boleh kosong

GO

--- KONFIRMASI JUMLAH DATA YANG BERHASIL DIMUAT
PRINT 'Data Dim_Transaksi selesai dimuat. Jumlah baris baru: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ===================================================================
-- LOAD DATA KE DIMENSI PRODUK
-- ===================================================================

--- MEMUAT DATA KE DIM_PRODUK
--- Melakukan transformasi pada kolom Sheet dari VARCHAR ke INT
--- Hanya memasukkan produk yang belum ada berdasarkan Barcode
PRINT 'Memuat data ke Dim_Produk (dengan konversi untuk Sheet)...';

INSERT INTO Dim_Produk (Barcode, Name, Dosage_form, Type, Sheet)
SELECT DISTINCT
    TS.Barcode,                   --- Barcode produk
    TS.Name,                      --- Nama produk
    TS.Dosage_form,              --- Bentuk dosis
    TS.Type,                     --- Jenis produk
    --- TRANSFORMASI: Konversi Sheet dari VARCHAR ke INT
    --- Jika bukan numerik, akan diset NULL
    CASE
        WHEN ISNUMERIC(TS.Sheet) = 1 THEN CAST(TS.Sheet AS INT)
        ELSE NULL
    END AS CleanedSheet
FROM Temp_Sales TS
LEFT JOIN Dim_Produk DP ON TS.Barcode = DP.Barcode    --- Cek duplikasi berdasarkan Barcode
WHERE DP.Barcode IS NULL          --- Hanya produk yang belum ada
  AND TS.Barcode IS NOT NULL      --- Barcode tidak boleh NULL
  AND TS.Barcode <> '';           --- Barcode tidak boleh kosong

GO

--- KONFIRMASI JUMLAH DATA YANG BERHASIL DIMUAT
PRINT 'Data Dim_Produk selesai dimuat. Jumlah baris baru: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ===================================================================
-- LOAD DATA KE DIMENSI WAKTU
-- ===================================================================

--- MEMUAT DATA KE DIM_WAKTU
--- Melakukan transformasi format tanggal dan waktu
--- Menambahkan informasi hari, bulan, dan tahun
PRINT 'Memuat data ke Dim_Waktu...';

INSERT INTO Dim_Waktu (Addeddate, Time_, Day, Month, Year)
SELECT DISTINCT
    --- TRANSFORMASI: Konversi string tanggal ke DATE (format MM/DD/YYYY)
    CONVERT(DATE, TS.Addeddate, 101) AS CleanedAddeddate,
    --- TRANSFORMASI: Konversi string waktu ke TIME
    CONVERT(TIME, TS.Time_) AS CleanedTime,
    --- EKSTRAKSI: Nama hari dalam seminggu
    DATENAME(WEEKDAY, CONVERT(DATE, TS.Addeddate, 101)) AS DayName,
    --- EKSTRAKSI: Nama bulan
    DATENAME(MONTH, CONVERT(DATE, TS.Addeddate, 101)) AS MonthName,
    --- EKSTRAKSI: Tahun
    YEAR(CONVERT(DATE, TS.Addeddate, 101)) AS YearNum
FROM Temp_Sales TS
WHERE TRY_CONVERT(DATE, TS.Addeddate, 101) IS NOT NULL    --- Validasi format tanggal
  AND TRY_CONVERT(TIME, TS.Time_) IS NOT NULL             --- Validasi format waktu
  --- Cek duplikasi berdasarkan tanggal
  AND NOT EXISTS (SELECT 1 FROM Dim_Waktu DW WHERE DW.Addeddate = CONVERT(DATE, TS.Addeddate, 101));

GO

--- KONFIRMASI JUMLAH DATA YANG BERHASIL DIMUAT
PRINT 'Data Dim_Waktu selesai dimuat. Jumlah baris baru: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ===================================================================
-- LOAD DATA KE FACT TABLE (TABEL FAKTA)
-- ===================================================================

--- MEMUAT DATA KE FACT_SALES
--- Menggabungkan data dari semua tabel dimensi
--- Melakukan perhitungan bisnis untuk Total_Amount, Discount, dan Tax
PRINT 'Langkah 4: Memuat data ke Fact_Sales...';

INSERT INTO Fact_Sales (
    Invoice_ID,      --- Foreign Key ke Dim_Transaksi
    Product_ID,      --- Foreign Key ke Dim_Produk
    Date_ID,         --- Foreign Key ke Dim_Waktu
    Addeddate,       --- Tanggal transaksi
    Sales_Sheet,     --- Jumlah lembar terjual
    Sales_Pack,      --- Jumlah pack terjual
    Total_Amount,    --- Total nilai penjualan
    Discount,        --- Nilai diskon
    Tax              --- Nilai pajak
)
SELECT
    DT.Invoice_ID,                           --- ID dari tabel dimensi transaksi
    DP.Product_ID,                           --- ID dari tabel dimensi produk
    DW.Date_ID,                              --- ID dari tabel dimensi waktu
    DW.Addeddate AS FactAddeddate,          --- Tanggal dari dimensi waktu
    TS.Sales_Sheet,                          --- Data penjualan lembar
    TS.Sales_Pack,                           --- Data penjualan pack
    
    --- PERHITUNGAN BISNIS: Total Amount berdasarkan jenis produk
    CASE
        WHEN DP.Type = 'Drug' THEN ISNULL(TS.Sales_Sheet, 0) * 15000    --- Obat: Rp 15,000 per lembar
        WHEN DP.Type = 'Supply' THEN ISNULL(TS.Sales_Sheet, 0) * 10000  --- Supply: Rp 10,000 per lembar
        ELSE 0
    END AS Total_Amount_Calc,
    
    --- PERHITUNGAN BISNIS: Discount 10% untuk Invoice tertentu
    CASE
        WHEN TS.Invoice IN ('INV001', 'INV003', 'INV005') THEN
            (CASE
                WHEN DP.Type = 'Drug' THEN ISNULL(TS.Sales_Sheet, 0) * 15000 * 0.1
                WHEN DP.Type = 'Supply' THEN ISNULL(TS.Sales_Sheet, 0) * 10000 * 0.1
                ELSE 0
            END)
        ELSE 0
    END AS Discount_Calc,
    
    --- PERHITUNGAN BISNIS: Tax 10% dari total amount
    (CASE
        WHEN DP.Type = 'Drug' THEN ISNULL(TS.Sales_Sheet, 0) * 15000 * 0.1
        WHEN DP.Type = 'Supply' THEN ISNULL(TS.Sales_Sheet, 0) * 10000 * 0.1
        ELSE 0
    END) AS Tax_Calc

FROM Temp_Sales TS
--- JOIN dengan tabel dimensi untuk mendapatkan Foreign Key
JOIN Dim_Transaksi DT ON TS.Invoice = DT.Invoice
JOIN Dim_Produk DP ON TS.Barcode = DP.Barcode
JOIN Dim_Waktu DW ON CONVERT(DATE, TS.Addeddate, 101) = DW.Addeddate
--- Pastikan semua Foreign Key valid
WHERE DT.Invoice_ID IS NOT NULL 
  AND DP.Product_ID IS NOT NULL 
  AND DW.Date_ID IS NOT NULL;

GO

--- KONFIRMASI JUMLAH DATA YANG BERHASIL DIMUAT
PRINT 'Data Fact_Sales selesai dimuat. Jumlah baris baru: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ===================================================================
-- CLEANUP PROCESS (PEMBERSIHAN)
-- ===================================================================

--- MENGHAPUS TABEL SEMENTARA
--- Setelah ETL selesai, tabel temporary tidak diperlukan lagi
PRINT 'Langkah 5: Menghapus tabel sementara Temp_Sales...';

DROP TABLE IF EXISTS Temp_Sales;

GO

--- KONFIRMASI PEMBERSIHAN SELESAI
PRINT 'Tabel Temp_Sales berhasil dihapus.';

--- NOTIFIKASI AKHIR PROSES ETL
PRINT 'Proses ETL Selesai.';
