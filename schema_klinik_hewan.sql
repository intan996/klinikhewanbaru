-- ============================================================================
-- SISTEM INFORMASI KLINIK HEWAN (Veterinary Management System)
-- Database: klinik_hewan
-- ============================================================================

-- Drop database jika ada
DROP DATABASE IF EXISTS klinik_hewan;
CREATE DATABASE klinik_hewan;
\c klinik_hewan

-- ============================================================================
-- 1. CREATE TABLE - ENTITIES
-- ============================================================================

-- Tabel Pemilik Hewan
CREATE TABLE pemilik_hewan (
    id_pemilik SERIAL PRIMARY KEY,
    nama_pemilik VARCHAR(100) NOT NULL,
    no_telepon VARCHAR(15),
    alamat TEXT,
    email VARCHAR(100),
    tanggal_daftar TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Jenis Hewan
CREATE TABLE jenis_hewan (
    id_jenis SERIAL PRIMARY KEY,
    nama_jenis VARCHAR(50) NOT NULL UNIQUE,
    deskripsi TEXT
);

-- Tabel Ras Hewan
CREATE TABLE ras_hewan (
    id_ras SERIAL PRIMARY KEY,
    id_jenis INT NOT NULL,
    nama_ras VARCHAR(50) NOT NULL,
    FOREIGN KEY (id_jenis) REFERENCES jenis_hewan(id_jenis),
    UNIQUE(id_jenis, nama_ras)
);

-- Tabel Hewan Peliharaan
CREATE TABLE hewan_peliharaan (
    id_hewan SERIAL PRIMARY KEY,
    id_pemilik INT NOT NULL,
    id_jenis INT NOT NULL,
    id_ras INT NOT NULL,
    nama_hewan VARCHAR(100) NOT NULL,
    jenis_kelamin CHAR(1) CHECK (jenis_kelamin IN ('L', 'P')),
    tanggal_lahir DATE,
    berat_kg DECIMAL(5,2),
    tanggal_daftar TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pemilik) REFERENCES pemilik_hewan(id_pemilik),
    FOREIGN KEY (id_jenis) REFERENCES jenis_hewan(id_jenis),
    FOREIGN KEY (id_ras) REFERENCES ras_hewan(id_ras)
);

-- Tabel Spesialisasi Dokter
CREATE TABLE spesialisasi (
    id_spesialisasi SERIAL PRIMARY KEY,
    nama_spesialisasi VARCHAR(100) NOT NULL UNIQUE,
    deskripsi TEXT
);

-- Tabel Dokter Hewan
CREATE TABLE dokter_hewan (
    id_dokter SERIAL PRIMARY KEY,
    nama_dokter VARCHAR(100) NOT NULL,
    id_spesialisasi INT NOT NULL,
    no_sip VARCHAR(30) UNIQUE NOT NULL,
    no_telepon VARCHAR(15),
    email VARCHAR(100),
    status BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_spesialisasi) REFERENCES spesialisasi(id_spesialisasi)
);

-- Tabel Jadwal Praktek Dokter
CREATE TABLE jadwal_praktek_drh (
    id_jadwal SERIAL PRIMARY KEY,
    id_dokter INT NOT NULL,
    hari_praktek VARCHAR(10) NOT NULL,
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL,
    FOREIGN KEY (id_dokter) REFERENCES dokter_hewan(id_dokter)
);

-- Tabel Vaksin
CREATE TABLE vaksin (
    id_vaksin SERIAL PRIMARY KEY,
    nama_vaksin VARCHAR(100) NOT NULL,
    deskripsi TEXT,
    harga DECIMAL(10,2) NOT NULL
);

-- Tabel Jenis Tindakan Medis
CREATE TABLE jenis_tindakan_medis (
    id_tindakan SERIAL PRIMARY KEY,
    nama_tindakan VARCHAR(100) NOT NULL UNIQUE,
    deskripsi TEXT,
    harga_dasar DECIMAL(10,2) NOT NULL
);

-- Tabel Obat Hewan
CREATE TABLE obat_hewan (
    id_obat SERIAL PRIMARY KEY,
    nama_obat VARCHAR(100) NOT NULL,
    jenis_obat VARCHAR(50),
    satuan VARCHAR(20),
    harga_satuan DECIMAL(10,2) NOT NULL,
    keterangan TEXT
);

-- Tabel Stok Obat Hewan
CREATE TABLE stok_obat_hewan (
    id_stok SERIAL PRIMARY KEY,
    id_obat INT NOT NULL,
    jumlah_stok INT NOT NULL DEFAULT 0,
    stok_minimum INT DEFAULT 5,
    tanggal_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_obat) REFERENCES obat_hewan(id_obat),
    UNIQUE(id_obat)
);

-- Tabel Kunjungan Hewan
CREATE TABLE kunjungan (
    id_kunjungan SERIAL PRIMARY KEY,
    id_hewan INT NOT NULL,
    id_dokter INT NOT NULL,
    tanggal_kunjungan TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    keluhan TEXT,
    diagnosa TEXT,
    catatan_dokter TEXT,
    status_kunjungan VARCHAR(20) DEFAULT 'Selesai',
    FOREIGN KEY (id_hewan) REFERENCES hewan_peliharaan(id_hewan),
    FOREIGN KEY (id_dokter) REFERENCES dokter_hewan(id_dokter)
);

-- Tabel Rekam Medis Hewan
CREATE TABLE rekam_medis_hewan (
    id_rekam_medis SERIAL PRIMARY KEY,
    id_kunjungan INT NOT NULL,
    id_hewan INT NOT NULL,
    berat_saat_kunjungan DECIMAL(5,2),
    suhu_tubuh DECIMAL(4,2),
    tekanan_darah VARCHAR(20),
    hasil_pemeriksaan TEXT,
    FOREIGN KEY (id_kunjungan) REFERENCES kunjungan(id_kunjungan),
    FOREIGN KEY (id_hewan) REFERENCES hewan_peliharaan(id_hewan)
);

-- Tabel Diagnosis Hewan
CREATE TABLE diagnosis_hewan (
    id_diagnosis SERIAL PRIMARY KEY,
    id_kunjungan INT NOT NULL,
    nama_diagnosis VARCHAR(150) NOT NULL,
    tingkat_keparahan VARCHAR(20),
    FOREIGN KEY (id_kunjungan) REFERENCES kunjungan(id_kunjungan)
);

-- Tabel Tindakan Medis per Kunjungan
CREATE TABLE tindakan_medis_kunjungan (
    id_tindakan_medis SERIAL PRIMARY KEY,
    id_kunjungan INT NOT NULL,
    id_tindakan INT NOT NULL,
    jumlah INT DEFAULT 1,
    harga_tindakan DECIMAL(10,2),
    FOREIGN KEY (id_kunjungan) REFERENCES kunjungan(id_kunjungan),
    FOREIGN KEY (id_tindakan) REFERENCES jenis_tindakan_medis(id_tindakan)
);

-- Tabel Resep Hewan
CREATE TABLE resep_hewan (
    id_resep SERIAL PRIMARY KEY,
    id_kunjungan INT NOT NULL,
    id_obat INT NOT NULL,
    jumlah_obat INT NOT NULL,
    dosis VARCHAR(100),
    cara_pemberian VARCHAR(50),
    durasi_hari INT,
    tanggal_resep TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    catatan TEXT,
    FOREIGN KEY (id_kunjungan) REFERENCES kunjungan(id_kunjungan),
    FOREIGN KEY (id_obat) REFERENCES obat_hewan(id_obat)
);

-- Tabel Jadwal Vaksinasi
CREATE TABLE jadwal_vaksinasi (
    id_jadwal_vaksin SERIAL PRIMARY KEY,
    id_hewan INT NOT NULL,
    id_vaksin INT NOT NULL,
    tanggal_vaksin_terakhir DATE,
    tanggal_vaksin_berikutnya DATE,
    status_vaksinasi VARCHAR(20) DEFAULT 'Belum Vaksin',
    catatan TEXT,
    FOREIGN KEY (id_hewan) REFERENCES hewan_peliharaan(id_hewan),
    FOREIGN KEY (id_vaksin) REFERENCES vaksin(id_vaksin)
);

-- Tabel Riwayat Vaksinasi
CREATE TABLE riwayat_vaksinasi (
    id_riwayat_vaksin SERIAL PRIMARY KEY,
    id_hewan INT NOT NULL,
    id_vaksin INT NOT NULL,
    tanggal_vaksinasi DATE NOT NULL,
    nomor_batch VARCHAR(50),
    nama_dokter VARCHAR(100),
    catatan TEXT,
    FOREIGN KEY (id_hewan) REFERENCES hewan_peliharaan(id_hewan),
    FOREIGN KEY (id_vaksin) REFERENCES vaksin(id_vaksin)
);

-- Tabel Tagihan Klinik Hewan
CREATE TABLE tagihan_klinik_hewan (
    id_tagihan SERIAL PRIMARY KEY,
    id_kunjungan INT NOT NULL,
    id_hewan INT NOT NULL,
    id_pemilik INT NOT NULL,
    subtotal_layanan DECIMAL(12,2) DEFAULT 0,
    subtotal_obat DECIMAL(12,2) DEFAULT 0,
    total_tagihan DECIMAL(12,2),
    diskon DECIMAL(12,2) DEFAULT 0,
    total_bayar DECIMAL(12,2),
    status_pembayaran VARCHAR(20) DEFAULT 'Belum Bayar',
    tanggal_tagihan TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tanggal_pembayaran TIMESTAMP,
    metode_pembayaran VARCHAR(50),
    FOREIGN KEY (id_kunjungan) REFERENCES kunjungan(id_kunjungan),
    FOREIGN KEY (id_hewan) REFERENCES hewan_peliharaan(id_hewan),
    FOREIGN KEY (id_pemilik) REFERENCES pemilik_hewan(id_pemilik)
);

-- ============================================================================
-- 2. CREATE INDEX - UNTUK PERFORMA QUERY
-- ============================================================================

CREATE INDEX idx_hewan_pemilik ON hewan_peliharaan(id_pemilik);
CREATE INDEX idx_hewan_jenis ON hewan_peliharaan(id_jenis);
CREATE INDEX idx_kunjungan_hewan ON kunjungan(id_hewan);
CREATE INDEX idx_kunjungan_dokter ON kunjungan(id_dokter);
CREATE INDEX idx_kunjungan_tanggal ON kunjungan(tanggal_kunjungan);
CREATE INDEX idx_tagihan_kunjungan ON tagihan_klinik_hewan(id_kunjungan);
CREATE INDEX idx_tagihan_tanggal ON tagihan_klinik_hewan(tanggal_tagihan);
CREATE INDEX idx_jadwal_vaksin_hewan ON jadwal_vaksinasi(id_hewan);
CREATE INDEX idx_resep_obat ON resep_hewan(id_obat);

-- ============================================================================
-- 3. INSERT DATA DUMMY
-- ============================================================================

-- Data Jenis Hewan
INSERT INTO jenis_hewan (nama_jenis, deskripsi) VALUES
('Anjing', 'Anjing peliharaan'),
('Kucing', 'Kucing peliharaan'),
('Burung', 'Burung peliharaan'),
('Kelinci', 'Kelinci peliharaan'),
('Hamster', 'Hamster peliharaan');

-- Data Ras Hewan
INSERT INTO ras_hewan (id_jenis, nama_ras) VALUES
(1, 'Golden Retriever'), (1, 'Siberian Husky'), (1, 'Poodle'),
(2, 'Persia'), (2, 'Bengal'), (2, 'Siam'),
(3, 'Lovebird'), (3, 'Parkit'), (3, 'Burung Hantu'),
(4, 'Kelinci Holland'), (4, 'Kelinci Rex'),
(5, 'Hamster Sirian'), (5, 'Hamster Dwarf');

-- Data Spesialisasi
INSERT INTO spesialisasi (nama_spesialisasi, deskripsi) VALUES
('Bedah Hewan', 'Spesialis operasi bedah'),
('Penyakit Dalam', 'Spesialis penyakit dalam hewan'),
('Reproduksi', 'Spesialis reproduksi hewan'),
('Dermatologi', 'Spesialis penyakit kulit hewan'),
('Gigi Hewan', 'Spesialis gigi hewan');

-- Data Dokter Hewan
INSERT INTO dokter_hewan (nama_dokter, id_spesialisasi, no_sip, no_telepon, email, status) VALUES
('Dr. Budi Santoso, drh', 1, 'SIP-001/2023', '08123456789', 'budi@klinik.com', TRUE),
('Dr. Siti Nurhaliza, drh', 2, 'SIP-002/2023', '08234567890', 'siti@klinik.com', TRUE),
('Dr. Ahmad Wijaya, drh', 3, 'SIP-003/2023', '08345678901', 'ahmad@klinik.com', TRUE),
('Dr. Eka Putri, drh', 4, 'SIP-004/2023', '08456789012', 'eka@klinik.com', TRUE),
('Dr. Rudi Hermawan, drh', 5, 'SIP-005/2023', '08567890123', 'rudi@klinik.com', TRUE);

-- Data Jadwal Praktek Dokter
INSERT INTO jadwal_praktek_drh (id_dokter, hari_praktek, jam_mulai, jam_selesai) VALUES
(1, 'Senin', '08:00:00', '16:00:00'),
(1, 'Rabu', '08:00:00', '16:00:00'),
(1, 'Jumat', '08:00:00', '16:00:00'),
(2, 'Selasa', '09:00:00', '17:00:00'),
(2, 'Kamis', '09:00:00', '17:00:00'),
(3, 'Senin', '10:00:00', '18:00:00'),
(3, 'Jumat', '10:00:00', '18:00:00'),
(4, 'Selasa', '08:00:00', '16:00:00'),
(4, 'Sabtu', '08:00:00', '14:00:00'),
(5, 'Rabu', '09:00:00', '17:00:00'),
(5, 'Minggu', '09:00:00', '15:00:00');

-- Data Pemilik Hewan
INSERT INTO pemilik_hewan (nama_pemilik, no_telepon, alamat, email) VALUES
('Yudi Hermanto', '08111111111', 'Jl. Merdeka No. 10, Jakarta', 'yudi@email.com'),
('Sinta Dewi', '08222222222', 'Jl. Sudirman No. 20, Bandung', 'sinta@email.com'),
('Roni Wijaya', '08333333333', 'Jl. Ahmad Yani No. 30, Surabaya', 'roni@email.com'),
('Rina Kusuma', '08444444444', 'Jl. Diponegoro No. 40, Medan', 'rina@email.com'),
('Bambang Sutrisno', '08555555555', 'Jl. Gatot Subroto No. 50, Yogyakarta', 'bambang@email.com');

-- Data Hewan Peliharaan
INSERT INTO hewan_peliharaan (id_pemilik, id_jenis, id_ras, nama_hewan, jenis_kelamin, tanggal_lahir, berat_kg) VALUES
(1, 1, 1, 'Max', 'L', '2022-01-15', 28.5),
(1, 2, 4, 'Mittens', 'P', '2021-06-20', 3.2),
(2, 1, 2, 'Cinta', 'P', '2020-11-10', 25.0),
(3, 2, 5, 'Tiger', 'L', '2023-03-05', 4.8),
(4, 3, 8, 'Kiki', 'P', '2022-08-12', 0.15),
(5, 4, 10, 'Fluffy', 'P', '2023-05-22', 2.1);

-- Data Vaksin
INSERT INTO vaksin (nama_vaksin, deskripsi, harga) VALUES
('Vaksin Rabies', 'Vaksin untuk mencegah penyakit rabies', 150000),
('Vaksin Distemper', 'Vaksin untuk anjing/kucing', 120000),
('Vaksin FVRCP', 'Vaksin untuk kucing', 180000),
('Vaksin Leptospirosis', 'Vaksin untuk anjing', 100000),
('Vaksin Avian Flu', 'Vaksin untuk burung', 80000);

-- Data Jenis Tindakan Medis
INSERT INTO jenis_tindakan_medis (nama_tindakan, deskripsi, harga_dasar) VALUES
('Pemeriksaan Kesehatan', 'Pemeriksaan umum kesehatan hewan', 100000),
('Pembersihan Gigi', 'Scaling dan pembersihan gigi', 250000),
('Operasi Sterilisasi', 'Operasi sterilisasi/kastrasi', 500000),
('Injeksi', 'Pemberian injeksi obat', 75000),
('Penjahitan Luka', 'Perawatan dan penjahitan luka', 300000);

-- Data Obat Hewan
INSERT INTO obat_hewan (nama_obat, jenis_obat, satuan, harga_satuan, keterangan) VALUES
('Amoxicillin', 'Antibiotik', 'Tablet', 5000, 'Antibiotik spektrum luas'),
('Metronidazole', 'Antiparasit', 'Tablet', 8000, 'Untuk infeksi bakteri anaerob'),
('Vitamin C', 'Vitamin', 'Tablet', 3000, 'Suplemen vitamin C'),
('Insulin', 'Hormon', 'Botol 10ml', 150000, 'Untuk diabetes hewan'),
('Antacid', 'Pencernaan', 'Tablet', 4000, 'Untuk masalah pencernaan'),
('Eye Drop', 'Tetes mata', 'Botol 10ml', 50000, 'Tetes mata antiseptik'),
('Flea Spray', 'Antiparasit', 'Botol 100ml', 75000, 'Untuk mengatasi kutu'),
('Probiotik', 'Pencernaan', 'Tablet', 6000, 'Untuk kesehatan pencernaan');

-- Data Stok Obat
INSERT INTO stok_obat_hewan (id_obat, jumlah_stok, stok_minimum) VALUES
(1, 50, 10), (2, 30, 10), (3, 100, 20), (4, 5, 2),
(5, 40, 10), (6, 15, 5), (7, 20, 5), (8, 45, 10);

-- Data Kunjungan
INSERT INTO kunjungan (id_hewan, id_dokter, tanggal_kunjungan, keluhan, diagnosa, catatan_dokter) VALUES
(1, 1, '2024-01-10 09:30:00', 'Demam dan batuk', 'Pneumonia', 'Berikan antibiotik dan istirahat'),
(2, 2, '2024-01-11 10:00:00', 'Diare', 'Infeksi usus', 'Antibiotik dan diet khusus'),
(3, 3, '2024-01-12 14:30:00', 'Mau Sterilisasi', 'Sehat', 'Persiapan operasi sterilisasi'),
(4, 4, '2024-01-13 11:00:00', 'Gatal-gatal', 'Dermatitis alergi', 'Obat antihistamin'),
(5, 5, '2024-01-14 15:00:00', 'Sayap terlihat lemah', 'Kekurangan vitamin', 'Berikan suplemen vitamin');

-- Data Rekam Medis
INSERT INTO rekam_medis_hewan (id_kunjungan, id_hewan, berat_saat_kunjungan, suhu_tubuh, tekanan_darah, hasil_pemeriksaan) VALUES
(1, 1, 28.0, 39.5, '120/80', 'Paru-paru ada infiltrat'),
(2, 2, 3.1, 38.8, '90/60', 'Perut teraba lembek'),
(3, 3, 25.2, 38.5, '110/75', 'Pemeriksaan pre-operasi normal'),
(4, 4, 4.7, 38.6, '95/65', 'Kulit merah dan bersisik'),
(5, 5, 0.14, 40.2, 'Tidak terukur', 'Secara umum lemah');

-- Data Diagnosis
INSERT INTO diagnosis_hewan (id_kunjungan, nama_diagnosis, tingkat_keparahan) VALUES
(1, 'Pneumonia bakteri', 'Sedang'),
(2, 'Gastroenteritis infektif', 'Ringan'),
(3, 'Status pre-operasi', 'Normal'),
(4, 'Dermatitis alergi', 'Ringan'),
(5, 'Avitaminosis', 'Sedang');

-- Data Tindakan Medis per Kunjungan
INSERT INTO tindakan_medis_kunjungan (id_kunjungan, id_tindakan, jumlah, harga_tindakan) VALUES
(1, 1, 1, 100000),
(1, 4, 2, 75000),
(2, 1, 1, 100000),
(2, 4, 1, 75000),
(3, 1, 1, 100000),
(4, 1, 1, 100000),
(4, 4, 2, 75000),
(5, 1, 1, 100000);

-- Data Resep Hewan
INSERT INTO resep_hewan (id_kunjungan, id_obat, jumlah_obat, dosis, cara_pemberian, durasi_hari, catatan) VALUES
(1, 1, 2, '500mg', 'Oral 2x sehari', 7, 'Diminum sebelum makan'),
(1, 3, 1, '500mg', 'Oral 1x sehari', 10, 'Untuk meningkatkan imunitas'),
(2, 2, 3, '250mg', 'Oral 3x sehari', 5, 'Untuk infeksi usus'),
(2, 8, 1, '1 sachet', 'Oral 1x sehari', 7, 'Untuk kesehatan pencernaan'),
(4, 1, 1, '250mg', 'Oral 2x sehari', 10, 'Untuk infeksi kulit'),
(5, 3, 2, '100mg', 'Oral 2x sehari', 14, 'Vitamin untuk burung');

-- Data Jadwal Vaksinasi
INSERT INTO jadwal_vaksinasi (id_hewan, id_vaksin, tanggal_vaksin_terakhir, tanggal_vaksin_berikutnya, status_vaksinasi) VALUES
(1, 1, '2023-12-01', '2024-12-01', 'Sudah Vaksin'),
(1, 2, '2023-11-15', '2024-11-15', 'Sudah Vaksin'),
(2, 4, '2023-10-20', '2024-10-20', 'Sudah Vaksin'),
(3, 1, NULL, '2024-02-01', 'Belum Vaksin'),
(4, 4, '2024-01-01', '2025-01-01', 'Sudah Vaksin'),
(5, 5, NULL, '2024-03-15', 'Belum Vaksin');

-- Data Riwayat Vaksinasi
INSERT INTO riwayat_vaksinasi (id_hewan, id_vaksin, tanggal_vaksinasi, nomor_batch, nama_dokter, catatan) VALUES
(1, 1, '2023-12-01', 'BATCH-001', 'Dr. Budi Santoso', 'Vaksinasi rutin tahunan'),
(1, 2, '2023-11-15', 'BATCH-002', 'Dr. Budi Santoso', 'Vaksinasi rutin tahunan'),
(2, 4, '2023-10-20', 'BATCH-003', 'Dr. Siti Nurhaliza', 'Vaksinasi rutin'),
(4, 4, '2024-01-01', 'BATCH-004', 'Dr. Siti Nurhaliza', 'Vaksinasi awal');

-- Data Tagihan
INSERT INTO tagihan_klinik_hewan (id_kunjungan, id_hewan, id_pemilik, subtotal_layanan, subtotal_obat, total_tagihan, total_bayar, status_pembayaran, metode_pembayaran) VALUES
(1, 1, 1, 250000, 26000, 276000, 276000, 'Sudah Bayar', 'Tunai'),
(2, 2, 1, 175000, 19000, 194000, 194000, 'Sudah Bayar', 'Debit'),
(3, 3, 2, 100000, 0, 100000, 100000, 'Sudah Bayar', 'Tunai'),
(4, 4, 3, 250000, 13000, 263000, 263000, 'Sudah Bayar', 'Debit'),
(5, 5, 4, 100000, 18000, 118000, 118000, 'Sudah Bayar', 'Transfer');

-- ============================================================================
-- 4. CREATE VIEWS
-- ============================================================================

-- View: Status Vaksinasi Hewan
CREATE VIEW vw_status_vaksinasi AS
SELECT 
    hp.id_hewan,
    hp.nama_hewan,
    ph.nama_pemilik,
    jh.nama_jenis,
    v.nama_vaksin,
    jv.tanggal_vaksin_terakhir,
    jv.tanggal_vaksin_berikutnya,
    jv.status_vaksinasi,
    CASE 
        WHEN jv.tanggal_vaksin_berikutnya IS NOT NULL 
            AND jv.tanggal_vaksin_berikutnya <= CURRENT_DATE + INTERVAL '7 days'
            AND jv.tanggal_vaksin_berikutnya > CURRENT_DATE
        THEN 'Akan Jatuh Tempo'
        WHEN jv.tanggal_vaksin_berikutnya IS NOT NULL 
            AND jv.tanggal_vaksin_berikutnya <= CURRENT_DATE
        THEN 'Sudah Melewati'
        ELSE 'Terjadwal'
    END AS status_jadwal
FROM hewan_peliharaan hp
JOIN pemilik_hewan ph ON hp.id_pemilik = ph.id_pemilik
JOIN jenis_hewan jh ON hp.id_jenis = jh.id_jenis
JOIN jadwal_vaksinasi jv ON hp.id_hewan = jv.id_hewan
JOIN vaksin v ON jv.id_vaksin = v.id_vaksin
ORDER BY jv.tanggal_vaksin_berikutnya;

-- View: Stok Obat Menjipis
CREATE VIEW vw_stok_obat_menjipis AS
SELECT 
    oh.id_obat,
    oh.nama_obat,
    oh.jenis_obat,
    soh.jumlah_stok,
    soh.stok_minimum,
    CASE 
        WHEN soh.jumlah_stok <= soh.stok_minimum THEN 'KRITIS'
        WHEN soh.jumlah_stok <= soh.stok_minimum * 1.5 THEN 'MENJIPIS'
        ELSE 'NORMAL'
    END AS status_stok
FROM obat_hewan oh
JOIN stok_obat_hewan soh ON oh.id_obat = soh.id_obat
WHERE soh.jumlah_stok <= soh.stok_minimum * 1.5
ORDER BY soh.jumlah_stok ASC;

-- View: Riwayat Medis Lengkap per Hewan
CREATE VIEW vw_riwayat_medis_hewan AS
SELECT 
    hp.id_hewan,
    hp.nama_hewan,
    ph.nama_pemilik,
    jh.nama_jenis,
    rh.nama_ras,
    k.tanggal_kunjungan,
    dh.nama_dokter,
    k.keluhan,
    k.diagnosa,
    dgh.nama_diagnosis,
    rm.suhu_tubuh,
    rm.berat_saat_kunjungan,
    rm.tekanan_darah,
    k.catatan_dokter
FROM hewan_peliharaan hp
JOIN pemilik_hewan ph ON hp.id_pemilik = ph.id_pemilik
JOIN jenis_hewan jh ON hp.id_jenis = jh.id_jenis
JOIN ras_hewan rh ON hp.id_ras = rh.id_ras
JOIN kunjungan k ON hp.id_hewan = k.id_hewan
LEFT JOIN dokter_hewan dh ON k.id_dokter = dh.id_dokter
LEFT JOIN rekam_medis_hewan rm ON k.id_kunjungan = rm.id_kunjungan
LEFT JOIN diagnosis_hewan dgh ON k.id_kunjungan = dgh.id_kunjungan
ORDER BY k.tanggal_kunjungan DESC;

-- View: Detail Tagihan per Kunjungan
CREATE VIEW vw_detail_tagihan AS
SELECT 
    tkh.id_tagihan,
    tkh.id_kunjungan,
    hp.nama_hewan,
    ph.nama_pemilik,
    k.tanggal_kunjungan,
    dh.nama_dokter,
    tkh.subtotal_layanan,
    tkh.subtotal_obat,
    tkh.diskon,
    tkh.total_bayar,
    tkh.status_pembayaran,
    tkh.metode_pembayaran
FROM tagihan_klinik_hewan tkh
JOIN kunjungan k ON tkh.id_kunjungan = k.id_kunjungan
JOIN hewan_peliharaan hp ON k.id_hewan = hp.id_hewan
JOIN pemilik_hewan ph ON hp.id_pemilik = ph.id_pemilik
JOIN dokter_hewan dh ON k.id_dokter = dh.id_dokter;

-- ============================================================================
-- 5. CREATE TRIGGERS
-- ============================================================================

-- TRIGGER 1: Kurangi Stok Obat saat Resep di-Insert
CREATE OR REPLACE FUNCTION fn_kurangi_stok_obat()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE stok_obat_hewan
    SET jumlah_stok = jumlah_stok - NEW.jumlah_obat,
        tanggal_update = CURRENT_TIMESTAMP
    WHERE id_obat = NEW.id_obat;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_kurangi_stok_obat
AFTER INSERT ON resep_hewan
FOR EACH ROW
EXECUTE FUNCTION fn_kurangi_stok_obat();

-- TRIGGER 2: Insert Jadwal Vaksinasi Otomatis saat Vaksinasi Dilakukan
CREATE OR REPLACE FUNCTION fn_insert_jadwal_vaksinasi_otomatis()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert atau update jadwal vaksinasi berikutnya (12 bulan kemudian)
    INSERT INTO jadwal_vaksinasi (id_hewan, id_vaksin, tanggal_vaksin_terakhir, tanggal_vaksin_berikutnya, status_vaksinasi)
    VALUES (NEW.id_hewan, NEW.id_vaksin, NEW.tanggal_vaksinasi, 
            NEW.tanggal_vaksinasi + INTERVAL '12 months', 'Sudah Vaksin')
    ON CONFLICT (id_hewan, id_vaksin) DO UPDATE
    SET tanggal_vaksin_terakhir = NEW.tanggal_vaksinasi,
        tanggal_vaksin_berikutnya = NEW.tanggal_vaksinasi + INTERVAL '12 months',
        status_vaksinasi = 'Sudah Vaksin';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_insert_jadwal_vaksinasi_otomatis
AFTER INSERT ON riwayat_vaksinasi
FOR EACH ROW
EXECUTE FUNCTION fn_insert_jadwal_vaksinasi_otomatis();

-- TRIGGER 3: Hitung Total Tagihan Otomatis
CREATE OR REPLACE FUNCTION fn_hitung_total_tagihan()
RETURNS TRIGGER AS $$
DECLARE
    v_subtotal_layanan DECIMAL(12,2);
    v_subtotal_obat DECIMAL(12,2);
BEGIN
    -- Hitung subtotal layanan (tindakan medis)
    SELECT COALESCE(SUM(harga_tindakan * jumlah), 0)
    INTO v_subtotal_layanan
    FROM tindakan_medis_kunjungan
    WHERE id_kunjungan = NEW.id_kunjungan;
    
    -- Hitung subtotal obat (resep)
    SELECT COALESCE(SUM(oh.harga_satuan * rh.jumlah_obat), 0)
    INTO v_subtotal_obat
    FROM resep_hewan rh
    JOIN obat_hewan oh ON rh.id_obat = oh.id_obat
    WHERE rh.id_kunjungan = NEW.id_kunjungan;
    
    -- Update tagihan
    UPDATE tagihan_klinik_hewan
    SET subtotal_layanan = v_subtotal_layanan,
        subtotal_obat = v_subtotal_obat,
        total_tagihan = v_subtotal_layanan + v_subtotal_obat,
        total_bayar = v_subtotal_layanan + v_subtotal_obat - COALESCE(diskon, 0)
    WHERE id_tagihan = NEW.id_tagihan;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hitung_total_tagihan
AFTER UPDATE ON tagihan_klinik_hewan
FOR EACH ROW
EXECUTE FUNCTION fn_hitung_total_tagihan();

-- ============================================================================
-- 6. CREATE STORED PROCEDURES
-- ============================================================================

-- STORED PROCEDURE 1: Hitung Total Tagihan per Kunjungan
CREATE OR REPLACE FUNCTION sp_hitung_tagihan_kunjungan(
    p_id_kunjungan INT,
    OUT p_subtotal_layanan DECIMAL,
    OUT p_subtotal_obat DECIMAL,
    OUT p_total_tagihan DECIMAL
)
AS $$
BEGIN
    -- Hitung subtotal layanan
    SELECT COALESCE(SUM(tmk.harga_tindakan * tmk.jumlah), 0)
    INTO p_subtotal_layanan
    FROM tindakan_medis_kunjungan tmk
    WHERE tmk.id_kunjungan = p_id_kunjungan;
    
    -- Hitung subtotal obat
    SELECT COALESCE(SUM(oh.harga_satuan * rh.jumlah_obat), 0)
    INTO p_subtotal_obat
    FROM resep_hewan rh
    JOIN obat_hewan oh ON rh.id_obat = oh.id_obat
    WHERE rh.id_kunjungan = p_id_kunjungan;
    
    -- Total tagihan
    p_total_tagihan := p_subtotal_layanan + p_subtotal_obat;
END;
$$ LANGUAGE plpgsql;

-- STORED PROCEDURE 2: Buat Tagihan Baru untuk Kunjungan
CREATE OR REPLACE FUNCTION sp_buat_tagihan_kunjungan(
    p_id_kunjungan INT,
    p_diskon DECIMAL DEFAULT 0,
    OUT p_id_tagihan INT,
    OUT p_total_bayar DECIMAL
)
AS $$
DECLARE
    v_subtotal_layanan DECIMAL;
    v_subtotal_obat DECIMAL;
    v_id_hewan INT;
    v_id_pemilik INT;
BEGIN
    -- Ambil id_hewan dari kunjungan
    SELECT id_hewan INTO v_id_hewan
    FROM kunjungan
    WHERE id_kunjungan = p_id_kunjungan;
    
    -- Ambil id_pemilik dari hewan
    SELECT id_pemilik INTO v_id_pemilik
    FROM hewan_peliharaan
    WHERE id_hewan = v_id_hewan;
    
    -- Hitung subtotal layanan dan obat
    SELECT COALESCE(SUM(harga_tindakan * jumlah), 0)
    INTO v_subtotal_layanan
    FROM tindakan_medis_kunjungan
    WHERE id_kunjungan = p_id_kunjungan;
    
    SELECT COALESCE(SUM(oh.harga_satuan * rh.jumlah_obat), 0)
    INTO v_subtotal_obat
    FROM resep_hewan rh
    JOIN obat_hewan oh ON rh.id_obat = oh.id_obat
    WHERE rh.id_kunjungan = p_id_kunjungan;
    
    -- Insert tagihan
    INSERT INTO tagihan_klinik_hewan
    (id_kunjungan, id_hewan, id_pemilik, subtotal_layanan, subtotal_obat, total_tagihan, diskon, total_bayar, status_pembayaran)
    VALUES
    (p_id_kunjungan, v_id_hewan, v_id_pemilik, v_subtotal_layanan, v_subtotal_obat,
     v_subtotal_layanan + v_subtotal_obat, p_diskon,
     (v_subtotal_layanan + v_subtotal_obat) - p_diskon, 'Belum Bayar')
    RETURNING id_tagihan, total_bayar INTO p_id_tagihan, p_total_bayar;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. QUERY ANALITIK & PELAPORAN
-- ============================================================================

-- Query 1: Pendapatan Klinik per Bulan per Jenis Layanan
SELECT 
    TO_CHAR(k.tanggal_kunjungan, 'YYYY-MM') AS bulan,
    jtm.nama_tindakan,
    COUNT(*) AS jumlah_kunjungan,
    SUM(tmk.harga_tindakan * tmk.jumlah) AS total_pendapatan
FROM kunjungan k
JOIN tindakan_medis_kunjungan tmk ON k.id_kunjungan = tmk.id_kunjungan
JOIN jenis_tindakan_medis jtm ON tmk.id_tindakan = jtm.id_tindakan
GROUP BY TO_CHAR(k.tanggal_kunjungan, 'YYYY-MM'), jtm.nama_tindakan
ORDER BY bulan DESC, total_pendapatan DESC;

-- Query 2: Jenis Hewan Paling Banyak Ditangani
SELECT 
    jh.nama_jenis,
    COUNT(*) AS jumlah_kunjungan,
    COUNT(DISTINCT k.id_hewan) AS jumlah_hewan
FROM kunjungan k
JOIN hewan_peliharaan hp ON k.id_hewan = hp.id_hewan
JOIN jenis_hewan jh ON hp.id_jenis = jh.id_jenis
GROUP BY jh.nama_jenis
ORDER BY jumlah_kunjungan DESC;

-- Query 3: Tren Kunjungan Harian dalam 1 Bulan Terakhir
SELECT 
    DATE(k.tanggal_kunjungan) AS tanggal_kunjungan,
    COUNT(*) AS jumlah_kunjungan,
    COUNT(DISTINCT k.id_hewan) AS jumlah_hewan_unik
FROM kunjungan k
WHERE k.tanggal_kunjungan >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(k.tanggal_kunjungan)
ORDER BY tanggal_kunjungan DESC;

-- Query 4: Dokter Hewan dengan Jumlah Kunjungan Terbanyak
SELECT 
    dh.id_dokter,
    dh.nama_dokter,
    s.nama_spesialisasi,
    COUNT(*) AS jumlah_kunjungan,
    AVG(EXTRACT(EPOCH FROM (k.tanggal_kunjungan - k.tanggal_kunjungan))::INT) AS rata_durasi_menit
FROM kunjungan k
JOIN dokter_hewan dh ON k.id_dokter = dh.id_dokter
JOIN spesialisasi s ON dh.id_spesialisasi = s.id_spesialisasi
GROUP BY dh.id_dokter, dh.nama_dokter, s.nama_spesialisasi
ORDER BY jumlah_kunjungan DESC;

-- Query 5: Obat Paling Sering Diresepkan
SELECT 
    oh.nama_obat,
    oh.jenis_obat,
    COUNT(*) AS jumlah_resep,
    SUM(rh.jumlah_obat) AS total_jumlah,
    SUM(oh.harga_satuan * rh.jumlah_obat) AS total_nilai
FROM resep_hewan rh
JOIN obat_hewan oh ON rh.id_obat = oh.id_obat
GROUP BY oh.id_obat, oh.nama_obat, oh.jenis_obat
ORDER BY jumlah_resep DESC;

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
