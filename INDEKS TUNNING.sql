USE PharmacyDW;
GO

-- ... (Bagian atas skrip Anda untuk menghapus PK, menambah PK Nonclustered, membuat CCI, membuat indeks Dim_Produk dan Dim_Waktu tetap sama, karena sepertinya sudah berhasil atau dilewati dengan benar) ...

PRINT 'Membuat Filtered Index pada Fact_Sales untuk transaksi dalam rentang tanggal tertentu...';
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Fact_Sales') AND name = 'idx_recent_transactions')
BEGIN
    -- Menggunakan rentang tanggal tetap sebagai contoh, berdasarkan tanggal penyelesaian simulasi 26 Mei 2025
    -- Ini mencakup data dari 26 April 2025 hingga 25 Mei 2025 (kurang lebih 30 hari)
    -- Sesuaikan rentang ini jika data dummy Anda memiliki tanggal yang berbeda atau jika Anda punya preferensi lain.
    CREATE NONCLUSTERED INDEX idx_recent_transactions
    ON Fact_Sales (Addeddate) -- Kolom yang diindeks
    -- INCLUDE (kolom_lain_jika_perlu_untuk_covering) -- Opsional
    WHERE Addeddate >= '2025-04-26' AND Addeddate < '2025-05-27'; -- Klausa WHERE dengan rentang tanggal tetap
    PRINT 'Filtered Index idx_recent_transactions pada Fact_Sales berhasil dibuat (dengan rentang tanggal tetap).';
END
ELSE
BEGIN
    PRINT 'Filtered Index idx_recent_transactions pada Fact_Sales sudah ada.';
END
GO

PRINT 'Proses pembuatan indeks selesai.'; -- Tanda kutip penutup ditambahkan
GO
