USE PharmacyDW;
GO

-- Query 1: Total penjualan per bulan
SELECT DW.Month, DW.Year, SUM(FS.Total_Amount) AS Total_Penjualan
FROM Fact_Sales FS
JOIN Dim_Waktu DW ON FS.Date_ID = DW.Date_ID
GROUP BY DW.Month, DW.Year
ORDER BY DW.Year, DW.Month;
GO

-- Query 2: Rata-rata transaksi (disesuaikan karena tidak ada dimensi pelanggan)
-- Rata-rata jumlah unit terjual (Sales_Sheet) per transaksi
SELECT AVG(CAST(FS.Sales_Sheet AS FLOAT)) AS Avg_Units_Per_Transaction
FROM Fact_Sales FS;
GO

-- Query 3: Produk terlaris (disesuaikan karena tidak ada dimensi wilayah)
-- Produk dengan jumlah unit terjual terbanyak
SELECT DP.Name, DP.Type, SUM(FS.Sales_Sheet) AS Total_Units_Sold
FROM Fact_Sales FS
JOIN Dim_Produk DP ON FS.Product_ID = DP.Product_ID
GROUP BY DP.Name, DP.Type
ORDER BY Total_Units_Sold DESC;
GO

-- Query 4: Tren pertumbuhan tahunan
SELECT DW.Year, SUM(FS.Total_Amount) AS Total_Penjualan
FROM Fact_Sales FS
JOIN Dim_Waktu DW ON FS.Date_ID = DW.Date_ID
GROUP BY DW.Year
ORDER BY DW.Year;
GO
