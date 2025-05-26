USE PharmacyDW;

GO

--- INISIALISASI DAN NOTIFIKASI AWAL
--- Memberikan informasi kepada user tentang proses yang akan dimulai
PRINT 'Memulai Proses ETL dari CSV...';

--- PERINGATAN PENTING TENTANG KONFIGURASI
--- Menginformasikan bahwa ERRORFILE dinonaktifkan untuk diagnosis
--- Mengingatkan tentang permission file CSV
PRINT 'PERHATIAN: Opsi ERRORFILE pada BULK INSERT dinonaktifkan sepenuhnya untuk diagnosis ini.';
PRINT 'PASTIKAN IZIN AKSES FILE CSV UNTUK NT SERVICE\MSSQL$SQLEXPRESS SUDAH BENAR!';

-- ===================================================================
-- PERSIAPAN TABEL SEMENTARA
-- ===================================================================

--- MEMBUAT TABEL SEMENTARA TEMP_SALES
--- Tabel ini akan menjadi tempat penyimpanan sementara data dari CSV
--- Sebelum data ditransformasi ke tabel dimensi dan fakta
PRINT 'Langkah 1: Membuat tabel sementara Temp_Sales...';

--- MENGHAPUS TABEL TEMP_SALES JIKA SUDAH ADA
--- Untuk memastikan proses berjalan bersih tanpa konflik
DROP TABLE IF EXISTS Temp_Sales;

GO

--- MEMBUAT STRUKTUR TABEL TEMP_SALES
--- Menggunakan VARCHAR untuk semua kolom agar fleksibel menerima data CSV
--- Sheet dibuat sebagai VARCHAR untuk menghindari error konversi saat import
CREATE TABLE Temp_Sales (
    Invoice VARCHAR(50),        --- ID Invoice transaksi
    Barcode VARCHAR(50),        --- Barcode produk
    Name VARCHAR(100),          --- Nama produk
    Dosage_form VARCHAR(50),    --- Bentuk dosis obat
    Sheet VARCHAR(50),          --- Jumlah lembar (sementara VARCHAR)
    Sales_Sheet INT,            --- Penjualan per lembar
    Sales_Pack INT,             --- Penjualan per pack
    Addeddate VARCHAR(20),      --- Tanggal ditambahkan (format string)
    Time_ VARCHAR(15),          --- Waktu transaksi
    Type VARCHAR(20)            --- Jenis produk (Drug/Supply)
);

GO

--- KONFIRMASI PEMBUATAN TABEL
PRINT 'Tabel Temp_Sales berhasil dibuat dengan Sheet sebagai VARCHAR.';

-- ===================================================================
-- PROSES IMPORT DATA DARI CSV
-- ===================================================================

--- MEMULAI PROSES BULK INSERT
--- Mengimpor data dari file CSV ke tabel sementara
PRINT 'Langkah 2: Mengimpor data dari CSV ke Temp_Sales (TANPA ERRORFILE)...';

--- MENGGUNAKAN TRY-CATCH UNTUK MENANGANI ERROR
--- Jika terjadi error, akan ditangkap dan ditampilkan pesan yang informatif
BEGIN TRY
    --- BULK INSERT UNTUK MENGIMPOR DATA CSV
    --- FORMAT CSV dengan parser bawaan SQL Server
    --- FIRSTROW=2 karena baris pertama adalah header
    BULK INSERT Temp_Sales
    FROM 'E:\TUBES_DW\archive (1)\PharmacyTransactionalDataset\global_test_set.csv'
    WITH (
        FORMAT = 'CSV',          --- Menggunakan parser CSV bawaan SQL Server
        FIRSTROW = 2,            --- Mulai dari baris ke-2 (skip header)
        TABLOCK                  --- Lock tabel untuk performa yang lebih baik
        --- ERRORFILE sengaja tidak digunakan untuk diagnosis
        , MAXERRORS = 1000       --- Maksimal 1000 error yang diizinkan
        , KEEPNULLS              --- Mempertahankan nilai NULL
    );
    
    --- KONFIRMASI BERHASIL DAN MENAMPILKAN JUMLAH RECORD
    PRINT 'BULK INSERT ke Temp_Sales selesai. Periksa jumlah baris yang diimpor.';
    SELECT COUNT(*) AS JumlahBarisDiTempSales FROM Temp_Sales;

END TRY
BEGIN CATCH
    --- MENANGANI ERROR JIKA BULK INSERT GAGAL
    --- Memberikan informasi detail tentang error yang terjadi
    PRINT '===================================================================';
    PRINT 'TERJADI ERROR SAAT PROSES BULK INSERT!';
    PRINT 'Pesan Error SQL Server: ' + ERROR_MESSAGE();
    PRINT 'Detail error per baris tidak akan ada di file log karena ERRORFILE dinonaktifkan.';
    PRINT 'Pastikan file CSV ada di path yang benar dan SQL Server memiliki izin akses ke CSV.';
    PRINT 'Periksa juga apakah format CSV (ROWTERMINATOR, FIELDTERMINATOR jika tidak pakai FORMAT=CSV) sudah benar.';
    PRINT '===================================================================';
END CATCH

GO
