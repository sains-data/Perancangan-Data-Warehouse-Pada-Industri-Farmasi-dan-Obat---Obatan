USE master; -- Beralih ke database master untuk membuat database baru
GO

PRINT 'Memulai proses pembuatan database PharmacyDW di Drive D...';

-- ===================================================================
-- PERHATIAN: BAGIAN BERIKUT AKAN MENGHAPUS DATABASE PharmacyDW JIKA SUDAH ADA!
-- Ini dilakukan untuk memastikan database dibuat dari awal dengan lokasi file yang benar.
-- JANGAN JALANKAN BAGIAN INI JIKA ANDA MEMILIKI DATA PENTING DI PharmacyDW YANG TIDAK INGIN HILANG.
-- LAKUKAN BACKUP TERLEBIH DAHULU JIKA PERLU.
-- ===================================================================
IF DB_ID('PharmacyDW') IS NOT NULL
BEGIN
    PRINT 'Database PharmacyDW sudah ada. Menghapus database lama...';
    -- Set database ke single user untuk memastikan tidak ada koneksi aktif
    ALTER DATABASE PharmacyDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PharmacyDW;
    PRINT 'Database PharmacyDW lama berhasil dihapus.';
END
GO

-- ===================================================================
-- Langkah 1: Membuat Database PharmacyDW dengan File Data (.mdf) dan Log (.ldf) di Drive D
-- Ganti 'D:\SQL_Data\PharmacyDW\' dengan path folder yang sudah Anda siapkan dan beri izin.
-- ===================================================================
PRINT 'Langkah 1: Membuat database PharmacyDW dengan file primer dan log di Drive D...';
CREATE DATABASE PharmacyDW
ON PRIMARY 
(
    NAME = N'PharmacyDW_Data', -- Nama logika untuk file data utama
    FILENAME = N'D:\SQL_Data\PharmacyDW\PharmacyDW_Data.mdf', -- Path fisik file .mdf
    SIZE = 100MB,             -- Ukuran awal file data
    MAXSIZE = UNLIMITED,      -- Ukuran maksimum (bisa dibatasi jika perlu)
    FILEGROWTH = 64MB         -- Pertumbuhan otomatis file data
)
LOG ON 
(
    NAME = N'PharmacyDW_Log',  -- Nama logika untuk file log
    FILENAME = N'D:\SQL_Data\PharmacyDW\PharmacyDW_Log.ldf',  -- Path fisik file .ldf
    SIZE = 50MB,              -- Ukuran awal file log
    MAXSIZE = 2048MB,         -- Ukuran maksimum file log
    FILEGROWTH = 32MB          -- Pertumbuhan otomatis file log
);
GO
PRINT 'Database PharmacyDW berhasil dibuat di Drive D.';

-- ===================================================================
-- Langkah 2: Beralih ke Database PharmacyDW yang Baru Dibuat
-- ===================================================================
USE PharmacyDW;
GO
PRINT 'Berhasil beralih ke konteks database PharmacyDW.';

-- ===================================================================
-- Langkah 3: Membuat Filegroup DW_FactGroup
-- ===================================================================
PRINT 'Langkah 3: Membuat Filegroup DW_FactGroup...';
IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = N'DW_FactGroup')
BEGIN
    ALTER DATABASE PharmacyDW
    ADD FILEGROUP DW_FactGroup;
    PRINT 'Filegroup DW_FactGroup berhasil dibuat.';
END
ELSE
BEGIN
    PRINT 'Filegroup DW_FactGroup sudah ada.';
END
GO

-- ===================================================================
-- Langkah 4: Menambahkan File Data Sekunder (.ndf) ke DW_FactGroup di Drive D
-- Ganti 'D:\SQL_Data\PharmacyDW\' dengan path folder yang sudah Anda siapkan dan beri izin.
-- ===================================================================
PRINT 'Langkah 4: Menambahkan file data sekunder (.ndf) ke DW_FactGroup di Drive D...';
IF NOT EXISTS (SELECT 1 FROM sys.database_files WHERE name = N'PharmacyDW_FactData_NDF')
BEGIN
    ALTER DATABASE PharmacyDW
    ADD FILE
    (
        NAME = N'PharmacyDW_FactData_NDF', -- Nama logika file data sekunder
        FILENAME = N'D:\SQL_Data\PharmacyDW\PharmacyDW_Fact.ndf', -- Path fisik file .ndf
        SIZE = 200MB,             -- Ukuran awal file data sekunder
        FILEGROWTH = 100MB        -- Pertumbuhan otomatis
    )
    TO FILEGROUP DW_FactGroup;
    PRINT 'File PharmacyDW_Fact.ndf berhasil ditambahkan ke filegroup DW_FactGroup di Drive D.';
END
ELSE
BEGIN
    PRINT 'File data sekunder dengan nama logika PharmacyDW_FactData_NDF sudah ada.';
END
GO

PRINT 'Proses penyiapan database PharmacyDW dengan file di Drive D selesai.';
PRINT 'Anda sekarang bisa melanjutkan dengan membuat tabel dan proses ETL.';
