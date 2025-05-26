-- Pastikan Anda menggunakan database yang benar
USE PharmacyDW;
GO

-- ===================================================================================
-- LANGKAH 1: PEMBUATAN FILEGROUP (JIKA BELUM ADA)
-- Aktifkan dan sesuaikan jika diperlukan.
-- ===================================================================================
/*
IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'DW_FactGroup')
BEGIN
    ALTER DATABASE PharmacyDW
    ADD FILEGROUP DW_FactGroup;
    PRINT 'Filegroup DW_FactGroup berhasil dibuat.';

    ALTER DATABASE PharmacyDW
    ADD FILE
    (
        NAME = N'DW_FactGroup_File1',
        FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL_ आपकी_Instance\MSSQL\DATA\DW_FactGroup_File1.ndf', -- << GANTI PATH INI
        SIZE = 100MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 64MB
    )
    TO FILEGROUP DW_FactGroup;
    PRINT 'File data untuk DW_FactGroup berhasil ditambahkan.';
END
ELSE
BEGIN
    PRINT 'Filegroup DW_FactGroup sudah ada.';
END
GO
*/

-- ===================================================================================
-- LANGKAH 2: MEMBUAT FUNGSI DAN SKEMA PARTISI
-- ===================================================================================
PRINT 'Membuat Partition Function PfSalesByMonth...';
IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = 'PfSalesByMonth')
BEGIN
    CREATE PARTITION FUNCTION PfSalesByMonth (DATE)
    AS RANGE RIGHT FOR VALUES (
        '2023-02-01', '2023-03-01', '2023-04-01', '2023-05-01', '2023-06-01',
        '2023-07-01', '2023-08-01', '2023-09-01', '2023-10-01', '2023-11-01',
        '2023-12-01', '2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01',
        '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01', '2024-09-01',
        '2024-10-01', '2024-11-01', '2024-12-01', '2025-01-01'
    );
    PRINT 'Partition Function PfSalesByMonth berhasil dibuat.';
END
ELSE
BEGIN
    PRINT 'Partition Function PfSalesByMonth sudah ada.';
END
GO

PRINT 'Membuat Partition Scheme PsSalesByMonth...';
IF NOT EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = 'PsSalesByMonth')
BEGIN
    IF EXISTS (SELECT 1 FROM sys.filegroups WHERE name = 'DW_FactGroup')
    BEGIN
        CREATE PARTITION SCHEME PsSalesByMonth
        AS PARTITION PfSalesByMonth
        ALL TO (DW_FactGroup);
        PRINT 'Partition Scheme PsSalesByMonth berhasil dibuat.';
    END
    ELSE
    BEGIN
        PRINT 'ERROR: Filegroup DW_FactGroup tidak ditemukan. Skema Partisi tidak dapat dibuat.';
    END
END
ELSE
BEGIN
    PRINT 'Partition Scheme PsSalesByMonth sudah ada.';
END
GO

-- ===================================================================================
-- LANGKAH 3: MEMBUAT TABEL DIMENSI
-- ===================================================================================
PRINT 'Membuat tabel Dim_Produk...';
IF OBJECT_ID('Dim_Produk', 'U') IS NULL
BEGIN
    CREATE TABLE Dim_Produk (
        Product_ID INT IDENTITY(1,1) PRIMARY KEY,
        Barcode VARCHAR(50) NOT NULL UNIQUE,
        Name VARCHAR(100) NOT NULL,
        Dosage_form VARCHAR(50),
        Type VARCHAR(20) CHECK (Type IN ('Drug', 'Supply')),
        Sheet INT
    ) WITH (DATA_COMPRESSION = ROW);
    PRINT 'Tabel Dim_Produk berhasil dibuat.';
END ELSE BEGIN PRINT 'Tabel Dim_Produk sudah ada.'; END
GO

PRINT 'Membuat tabel Dim_Waktu...';
IF OBJECT_ID('Dim_Waktu', 'U') IS NULL
BEGIN
    CREATE TABLE Dim_Waktu (
        Date_ID INT IDENTITY(1,1) PRIMARY KEY,
        Addeddate DATE NOT NULL UNIQUE,
        Time_ TIME,
        Day VARCHAR(10),
        Month VARCHAR(10),
        Year INT
    ) WITH (DATA_COMPRESSION = ROW);
    PRINT 'Tabel Dim_Waktu berhasil dibuat.';
END ELSE BEGIN PRINT 'Tabel Dim_Waktu sudah ada.'; END
GO

PRINT 'Membuat tabel Dim_Transaksi...';
IF OBJECT_ID('Dim_Transaksi', 'U') IS NULL
BEGIN
    CREATE TABLE Dim_Transaksi (
        Invoice_ID INT IDENTITY(1,1) PRIMARY KEY,
        Invoice VARCHAR(50) NOT NULL UNIQUE
    ) WITH (DATA_COMPRESSION = ROW);
    PRINT 'Tabel Dim_Transaksi berhasil dibuat.';
END ELSE BEGIN PRINT 'Tabel Dim_Transaksi sudah ada.'; END
GO

-- ===================================================================================
-- LANGKAH 4: MEMBUAT ATAU MEMPERBAIKI TABEL FAKTA (Fact_Sales)
-- ===================================================================================
PRINT 'Memproses tabel Fact_Sales...';
IF OBJECT_ID('Fact_Sales', 'U') IS NULL
BEGIN
    -- Buat tabel Fact_Sales jika belum ada, dengan PK NONCLUSTERED
    IF EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = 'PsSalesByMonth')
    BEGIN
        CREATE TABLE Fact_Sales (
            Invoice_ID INT NOT NULL,
            Product_ID INT NOT NULL,
            Date_ID INT NOT NULL,
            Addeddate DATE NOT NULL,
            Sales_Sheet INT,
            Sales_Pack INT,
            Total_Amount DECIMAL(18,2),
            Discount DECIMAL(18,2),
            Tax DECIMAL(18,2),
            CONSTRAINT PK_Fact_Sales PRIMARY KEY NONCLUSTERED (Invoice_ID, Product_ID, Date_ID, Addeddate),
            CONSTRAINT FK_Fact_Sales_Transaksi FOREIGN KEY (Invoice_ID) REFERENCES Dim_Transaksi(Invoice_ID),
            CONSTRAINT FK_Fact_Sales_Produk FOREIGN KEY (Product_ID) REFERENCES Dim_Produk(Product_ID),
            CONSTRAINT FK_Fact_Sales_Waktu FOREIGN KEY (Date_ID) REFERENCES Dim_Waktu(Date_ID)
        ) ON PsSalesByMonth (Addeddate);
        PRINT 'Tabel Fact_Sales berhasil dibuat dengan partisi dan PK Nonclustered.';
    END
    ELSE
    BEGIN
        PRINT 'ERROR: Partition Scheme PsSalesByMonth tidak ditemukan. Tabel Fact_Sales tidak dapat dibuat.';
    END
END
ELSE
BEGIN
    PRINT 'Tabel Fact_Sales sudah ada. Memeriksa Primary Key...';
    -- Periksa apakah PK adalah Clustered. GANTI 'PK_Fact_Sales' JIKA NAMA CONSTRAINT PK ANDA BERBEDA.
    DECLARE @PKName NVARCHAR(128);
    SELECT @PKName = name FROM sys.key_constraints WHERE type = 'PK' AND parent_object_id = OBJECT_ID('Fact_Sales');

    IF @PKName IS NOT NULL AND EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Fact_Sales') AND name = @PKName AND type_desc = 'CLUSTERED')
    BEGIN
        PRINT 'Primary Key (' + @PKName + ') pada Fact_Sales adalah CLUSTERED. Mencoba mengubah menjadi NONCLUSTERED...';
        BEGIN TRY
            -- Hapus Foreign Keys yang mereferensikan kolom PK JIKA ADA (biasanya tidak ada untuk tabel fakta)
            -- Contoh:
            -- IF OBJECT_ID('FK_SomeOtherTable_Fact_Sales', 'F') IS NOT NULL
            --     ALTER TABLE SomeOtherTable DROP CONSTRAINT FK_SomeOtherTable_Fact_Sales;

            ALTER TABLE Fact_Sales DROP CONSTRAINT PK_Fact_Sales; -- << GANTI 'PK_Fact_Sales' JIKA NAMA CONSTRAINT PK ANDA BERBEDA
            ALTER TABLE Fact_Sales ADD CONSTRAINT PK_Fact_Sales -- << GANTI 'PK_Fact_Sales' JIKA NAMA CONSTRAINT PK ANDA BERBEDA
                PRIMARY KEY NONCLUSTERED (Invoice_ID, Product_ID, Date_ID, Addeddate);
            PRINT 'Primary Key (' + @PKName + ') Fact_Sales berhasil diubah menjadi NONCLUSTERED.';
        END TRY
        BEGIN CATCH
            PRINT 'ERROR saat mengubah Primary Key Fact_Sales: ' + ERROR_MESSAGE();
            PRINT 'Pastikan tidak ada dependensi atau nama constraint PK sudah benar.';
        END CATCH
    END
    ELSE IF @PKName IS NOT NULL AND EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Fact_Sales') AND name = @PKName AND type_desc = 'NONCLUSTERED')
    BEGIN
        PRINT 'Primary Key (' + @PKName + ') pada Fact_Sales sudah NONCLUSTERED.';
    END
    ELSE
    BEGIN
        PRINT 'Primary Key pada Fact_Sales tidak ditemukan atau memiliki konfigurasi yang tidak terduga.';
    END
END
GO

-- ===================================================================================
-- LANGKAH 5: MEMBUAT CLUSTERED COLUMNSTORE INDEX PADA TABEL FAKTA
-- ===================================================================================
PRINT 'Membuat Clustered Columnstore Index pada Fact_Sales...';
IF OBJECT_ID('Fact_Sales', 'U') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Fact_Sales') AND type = 5) -- type 5 = Clustered Columnstore
BEGIN
    DECLARE @PKIsNonClustered BIT = 0;
    DECLARE @PKNameForCheck NVARCHAR(128);
    SELECT @PKNameForCheck = name FROM sys.key_constraints WHERE type = 'PK' AND parent_object_id = OBJECT_ID('Fact_Sales');

    IF @PKNameForCheck IS NOT NULL AND EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Fact_Sales') AND name = @PKNameForCheck AND type_desc = 'NONCLUSTERED')
        SET @PKIsNonClustered = 1;

    IF @PKIsNonClustered = 1
    BEGIN
        CREATE CLUSTERED COLUMNSTORE INDEX idx_cci_fact_sales
        ON Fact_Sales; -- CCI akan otomatis dipartisi karena tabel Fact_Sales sudah dipartisi.
        PRINT 'Clustered Columnstore Index idx_cci_fact_sales pada Fact_Sales BERHASIL dibuat.';
    END
    ELSE
    BEGIN
        PRINT 'WARNING: Primary Key pada Fact_Sales bukan Nonclustered atau PK tidak ditemukan. CCI tidak dibuat.';
        PRINT 'Silakan periksa konfigurasi Primary Key tabel Fact_Sales secara manual.';
    END
END
ELSE
BEGIN
    IF OBJECT_ID('Fact_Sales', 'U') IS NULL
    BEGIN
        PRINT 'Tabel Fact_Sales tidak ditemukan, CCI tidak dapat dibuat.';
    END
    ELSE
    BEGIN
        PRINT 'Clustered Columnstore Index pada Fact_Sales kemungkinan sudah ada.';
    END
END
GO

PRINT 'Proses pembuatan/penyesuaian skema data warehouse selesai.';
