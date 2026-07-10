"""
Sistem Informasi Klinik Hewan (Veterinary Management System)
Flask Application with PostgreSQL
"""

import os
from dotenv import load_dotenv
load_dotenv()
from datetime import datetime, timedelta
from functools import wraps
from flask import (Flask, render_template, request, jsonify, redirect, url_for, 
                   session, flash, send_file)
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import func, desc, text, and_, or_
from werkzeug.security import generate_password_hash, check_password_hash
import psycopg2
from psycopg2 import sql

# ============================================================================
# INISIALISASI FLASK & DATABASE
# ============================================================================

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-12345')

# Konfigurasi Database PostgreSQL dari Neon
DATABASE_URL = os.environ.get('DATABASE_URL')
if not DATABASE_URL:
    # Default untuk development (LOCAL PostgreSQL)
    DATABASE_URL = 'postgresql://postgres:password@localhost:5432/klinik_hewan'

app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JSON_SORT_KEYS'] = False

db = SQLAlchemy(app)
# ============================================================================
# CUSTOM JINJA2 FILTERS
# ============================================================================

@app.template_filter('strftime')
def strftime_filter(value, fmt='%d %B %Y'):
    """Format datetime object using strftime"""
    # Handle string 'now'
    if isinstance(value, str):
        if value.lower() == 'now':
            value = datetime.now()
        else:
            return value
    
    # Handle datetime object
    if value:
        return value.strftime(fmt)
    return ''

@app.template_filter('currency')
def currency_filter(value):
    """Format value as currency"""
    try:
        return f"Rp {int(value):,.0f}".replace(',', '.')
    except:
        return value

# ============================================================================
# DECORATOR LOGIN REQUIRED
# ============================================================================

def login_required(f):
    """Decorator untuk memerlukan login"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Anda harus login terlebih dahulu', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# ============================================================================
# MODEL DATABASE
# ============================================================================

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    nama_lengkap = db.Column(db.String(120), nullable=False)
    role = db.Column(db.String(20), default='staff')  # admin, staff, owner
    status = db.Column(db.Boolean, default=True)
    tanggal_daftar = db.Column(db.DateTime, default=datetime.utcnow)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class PemilikHewan(db.Model):
    __tablename__ = 'pemilik_hewan'
    id_pemilik = db.Column(db.Integer, primary_key=True)
    nama_pemilik = db.Column(db.String(100), nullable=False)
    no_telepon = db.Column(db.String(15))
    alamat = db.Column(db.Text)
    email = db.Column(db.String(100))
    tanggal_daftar = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    hewan_peliharaan = db.relationship('HewanPeliharaan', backref='pemilik', lazy=True, cascade='all, delete-orphan')
    tagihan = db.relationship('TagihanKlinik', backref='pemilik', lazy=True)

class JenisHewan(db.Model):
    __tablename__ = 'jenis_hewan'
    id_jenis = db.Column(db.Integer, primary_key=True)
    nama_jenis = db.Column(db.String(50), nullable=False, unique=True)
    deskripsi = db.Column(db.Text)
    
    ras = db.relationship('RasHewan', backref='jenis', lazy=True, cascade='all, delete-orphan')
    hewan = db.relationship('HewanPeliharaan', backref='jenis', lazy=True)

class RasHewan(db.Model):
    __tablename__ = 'ras_hewan'
    id_ras = db.Column(db.Integer, primary_key=True)
    id_jenis = db.Column(db.Integer, db.ForeignKey('jenis_hewan.id_jenis'), nullable=False)
    nama_ras = db.Column(db.String(50), nullable=False)
    
    hewan = db.relationship('HewanPeliharaan', backref='ras', lazy=True)

class HewanPeliharaan(db.Model):
    __tablename__ = 'hewan_peliharaan'
    id_hewan = db.Column(db.Integer, primary_key=True)
    id_pemilik = db.Column(db.Integer, db.ForeignKey('pemilik_hewan.id_pemilik'), nullable=False)
    id_jenis = db.Column(db.Integer, db.ForeignKey('jenis_hewan.id_jenis'), nullable=False)
    id_ras = db.Column(db.Integer, db.ForeignKey('ras_hewan.id_ras'), nullable=False)
    nama_hewan = db.Column(db.String(100), nullable=False)
    jenis_kelamin = db.Column(db.String(1))
    tanggal_lahir = db.Column(db.Date)
    berat_kg = db.Column(db.Numeric(5, 2))
    tanggal_daftar = db.Column(db.DateTime, default=datetime.utcnow)
    
    kunjungan = db.relationship('Kunjungan', backref='hewan', lazy=True, cascade='all, delete-orphan')
    jadwal_vaksinasi = db.relationship('JadwalVaksinasi', backref='hewan', lazy=True, cascade='all, delete-orphan')
    tagihan = db.relationship('TagihanKlinik', backref='hewan', lazy=True)

class Spesialisasi(db.Model):
    __tablename__ = 'spesialisasi'
    id_spesialisasi = db.Column(db.Integer, primary_key=True)
    nama_spesialisasi = db.Column(db.String(100), nullable=False, unique=True)
    deskripsi = db.Column(db.Text)
    
    dokter = db.relationship('DokterHewan', backref='spesialisasi', lazy=True)

class DokterHewan(db.Model):
    __tablename__ = 'dokter_hewan'
    id_dokter = db.Column(db.Integer, primary_key=True)
    nama_dokter = db.Column(db.String(100), nullable=False)
    id_spesialisasi = db.Column(db.Integer, db.ForeignKey('spesialisasi.id_spesialisasi'), nullable=False)
    no_sip = db.Column(db.String(30), unique=True, nullable=False)
    no_telepon = db.Column(db.String(15))
    email = db.Column(db.String(100))
    status = db.Column(db.Boolean, default=True)
    
    jadwal_praktek = db.relationship('JadwalPraktekDrh', backref='dokter', lazy=True, cascade='all, delete-orphan')
    kunjungan = db.relationship('Kunjungan', backref='dokter', lazy=True)

class JadwalPraktekDrh(db.Model):
    __tablename__ = 'jadwal_praktek_drh'
    id_jadwal = db.Column(db.Integer, primary_key=True)
    id_dokter = db.Column(db.Integer, db.ForeignKey('dokter_hewan.id_dokter'), nullable=False)
    hari_praktek = db.Column(db.String(10), nullable=False)
    jam_mulai = db.Column(db.Time, nullable=False)
    jam_selesai = db.Column(db.Time, nullable=False)

class Vaksin(db.Model):
    __tablename__ = 'vaksin'
    id_vaksin = db.Column(db.Integer, primary_key=True)
    nama_vaksin = db.Column(db.String(100), nullable=False)
    deskripsi = db.Column(db.Text)
    harga = db.Column(db.Numeric(10, 2), nullable=False)
    
    jadwal_vaksinasi = db.relationship('JadwalVaksinasi', backref='vaksin', lazy=True)
    riwayat_vaksinasi = db.relationship('RiwayatVaksinasi', backref='vaksin', lazy=True)

class JenisObat(db.Model):
    __tablename__ = 'obat_hewan'
    id_obat = db.Column(db.Integer, primary_key=True)
    nama_obat = db.Column(db.String(100), nullable=False)
    jenis_obat = db.Column(db.String(50))
    satuan = db.Column(db.String(20))
    harga_satuan = db.Column(db.Numeric(10, 2), nullable=False)
    keterangan = db.Column(db.Text)
    
    stok = db.relationship('StokObat', backref='obat', lazy=True, uselist=False)
    resep = db.relationship('ResepHewan', backref='obat', lazy=True)

class StokObat(db.Model):
    __tablename__ = 'stok_obat_hewan'
    id_stok = db.Column(db.Integer, primary_key=True)
    id_obat = db.Column(db.Integer, db.ForeignKey('obat_hewan.id_obat'), nullable=False, unique=True)
    jumlah_stok = db.Column(db.Integer, default=0)
    stok_minimum = db.Column(db.Integer, default=5)
    tanggal_update = db.Column(db.DateTime, default=datetime.utcnow)

class JenisTindakan(db.Model):
    __tablename__ = 'jenis_tindakan_medis'
    id_tindakan = db.Column(db.Integer, primary_key=True)
    nama_tindakan = db.Column(db.String(100), nullable=False, unique=True)
    deskripsi = db.Column(db.Text)
    harga_dasar = db.Column(db.Numeric(10, 2), nullable=False)
    
    tindakan_kunjungan = db.relationship('TindakanMedisKunjungan', backref='tindakan', lazy=True)

class Kunjungan(db.Model):
    __tablename__ = 'kunjungan'
    id_kunjungan = db.Column(db.Integer, primary_key=True)
    id_hewan = db.Column(db.Integer, db.ForeignKey('hewan_peliharaan.id_hewan'), nullable=False)
    id_dokter = db.Column(db.Integer, db.ForeignKey('dokter_hewan.id_dokter'), nullable=False)
    tanggal_kunjungan = db.Column(db.DateTime, default=datetime.utcnow)
    keluhan = db.Column(db.Text)
    diagnosa = db.Column(db.Text)
    catatan_dokter = db.Column(db.Text)
    status_kunjungan = db.Column(db.String(20), default='Selesai')
    
    rekam_medis = db.relationship('RekamMedis', backref='kunjungan', lazy=True, cascade='all, delete-orphan', uselist=False)
    diagnosis = db.relationship('Diagnosis', backref='kunjungan', lazy=True, cascade='all, delete-orphan')
    tindakan_medis = db.relationship('TindakanMedisKunjungan', backref='kunjungan', lazy=True, cascade='all, delete-orphan')
    resep = db.relationship('ResepHewan', backref='kunjungan', lazy=True, cascade='all, delete-orphan')
    tagihan = db.relationship('TagihanKlinik', backref='kunjungan', lazy=True, cascade='all, delete-orphan', uselist=False)

class RekamMedis(db.Model):
    __tablename__ = 'rekam_medis_hewan'
    id_rekam_medis = db.Column(db.Integer, primary_key=True)
    id_kunjungan = db.Column(db.Integer, db.ForeignKey('kunjungan.id_kunjungan'), nullable=False, unique=True)
    id_hewan = db.Column(db.Integer, db.ForeignKey('hewan_peliharaan.id_hewan'), nullable=False)
    berat_saat_kunjungan = db.Column(db.Numeric(5, 2))
    suhu_tubuh = db.Column(db.Numeric(4, 2))
    tekanan_darah = db.Column(db.String(20))
    hasil_pemeriksaan = db.Column(db.Text)

class Diagnosis(db.Model):
    __tablename__ = 'diagnosis_hewan'
    id_diagnosis = db.Column(db.Integer, primary_key=True)
    id_kunjungan = db.Column(db.Integer, db.ForeignKey('kunjungan.id_kunjungan'), nullable=False)
    nama_diagnosis = db.Column(db.String(150), nullable=False)
    tingkat_keparahan = db.Column(db.String(20))

class TindakanMedisKunjungan(db.Model):
    __tablename__ = 'tindakan_medis_kunjungan'
    id_tindakan_medis = db.Column(db.Integer, primary_key=True)
    id_kunjungan = db.Column(db.Integer, db.ForeignKey('kunjungan.id_kunjungan'), nullable=False)
    id_tindakan = db.Column(db.Integer, db.ForeignKey('jenis_tindakan_medis.id_tindakan'), nullable=False)
    jumlah = db.Column(db.Integer, default=1)
    harga_tindakan = db.Column(db.Numeric(10, 2))

class ResepHewan(db.Model):
    __tablename__ = 'resep_hewan'
    id_resep = db.Column(db.Integer, primary_key=True)
    id_kunjungan = db.Column(db.Integer, db.ForeignKey('kunjungan.id_kunjungan'), nullable=False)
    id_obat = db.Column(db.Integer, db.ForeignKey('obat_hewan.id_obat'), nullable=False)
    jumlah_obat = db.Column(db.Integer, nullable=False)
    dosis = db.Column(db.String(100))
    cara_pemberian = db.Column(db.String(50))
    durasi_hari = db.Column(db.Integer)
    tanggal_resep = db.Column(db.DateTime, default=datetime.utcnow)
    catatan = db.Column(db.Text)

class JadwalVaksinasi(db.Model):
    __tablename__ = 'jadwal_vaksinasi'
    id_jadwal_vaksin = db.Column(db.Integer, primary_key=True)
    id_hewan = db.Column(db.Integer, db.ForeignKey('hewan_peliharaan.id_hewan'), nullable=False)
    id_vaksin = db.Column(db.Integer, db.ForeignKey('vaksin.id_vaksin'), nullable=False)
    tanggal_vaksin_terakhir = db.Column(db.Date)
    tanggal_vaksin_berikutnya = db.Column(db.Date)
    status_vaksinasi = db.Column(db.String(20), default='Belum Vaksin')
    catatan = db.Column(db.Text)

class RiwayatVaksinasi(db.Model):
    __tablename__ = 'riwayat_vaksinasi'
    id_riwayat_vaksin = db.Column(db.Integer, primary_key=True)
    id_hewan = db.Column(db.Integer, db.ForeignKey('hewan_peliharaan.id_hewan'), nullable=False)
    id_vaksin = db.Column(db.Integer, db.ForeignKey('vaksin.id_vaksin'), nullable=False)
    tanggal_vaksinasi = db.Column(db.Date, nullable=False)
    nomor_batch = db.Column(db.String(50))
    nama_dokter = db.Column(db.String(100))
    catatan = db.Column(db.Text)

class TagihanKlinik(db.Model):
    __tablename__ = 'tagihan_klinik_hewan'
    id_tagihan = db.Column(db.Integer, primary_key=True)
    id_kunjungan = db.Column(db.Integer, db.ForeignKey('kunjungan.id_kunjungan'), nullable=False, unique=True)
    id_hewan = db.Column(db.Integer, db.ForeignKey('hewan_peliharaan.id_hewan'), nullable=False)
    id_pemilik = db.Column(db.Integer, db.ForeignKey('pemilik_hewan.id_pemilik'), nullable=False)
    subtotal_layanan = db.Column(db.Numeric(12, 2), default=0)
    subtotal_obat = db.Column(db.Numeric(12, 2), default=0)
    total_tagihan = db.Column(db.Numeric(12, 2))
    diskon = db.Column(db.Numeric(12, 2), default=0)
    total_bayar = db.Column(db.Numeric(12, 2))
    status_pembayaran = db.Column(db.String(20), default='Belum Bayar')
    tanggal_tagihan = db.Column(db.DateTime, default=datetime.utcnow)
    tanggal_pembayaran = db.Column(db.DateTime)
    metode_pembayaran = db.Column(db.String(50))

# ============================================================================
# ROUTES - AUTHENTICATION
# ============================================================================

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Login page"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if not username or not password:
            flash('Username dan password harus diisi', 'danger')
            return redirect(url_for('login'))
        
        user = User.query.filter_by(username=username).first()
        
        if user and user.check_password(password):
            if not user.status:
                flash('Akun Anda telah dinonaktifkan', 'danger')
                return redirect(url_for('login'))
            
            session['user_id'] = user.id
            session['username'] = user.username
            session['nama_lengkap'] = user.nama_lengkap
            session['role'] = user.role
            
            flash(f'Selamat datang, {user.nama_lengkap}!', 'success')
            return redirect(url_for('index'))
        else:
            flash('Username atau password salah', 'danger')
    
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    """Register page"""
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        nama_lengkap = request.form.get('nama_lengkap')
        
        # Validasi
        if not all([username, email, password, confirm_password, nama_lengkap]):
            flash('Semua field harus diisi', 'danger')
            return redirect(url_for('register'))
        
        if len(password) < 6:
            flash('Password minimal 6 karakter', 'danger')
            return redirect(url_for('register'))
        
        if password != confirm_password:
            flash('Password dan konfirmasi password tidak cocok', 'danger')
            return redirect(url_for('register'))
        
        # Cek duplikat
        if User.query.filter_by(username=username).first():
            flash('Username sudah terdaftar', 'danger')
            return redirect(url_for('register'))
        
        if User.query.filter_by(email=email).first():
            flash('Email sudah terdaftar', 'danger')
            return redirect(url_for('register'))
        
        try:
            user = User(
                username=username,
                email=email,
                nama_lengkap=nama_lengkap,
                role='staff'
            )
            user.set_password(password)
            
            db.session.add(user)
            db.session.commit()
            
            flash('Pendaftaran berhasil! Silakan login.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {str(e)}', 'danger')
    
    return render_template('register.html')

@app.route('/logout')
def logout():
    """Logout"""
    session.clear()
    flash('Anda telah logout', 'success')
    return redirect(url_for('login'))

# ============================================================================
# ROUTES - DASHBOARD & HOME
# ============================================================================

@app.route('/')
def index():
    """Halaman utama / dashboard"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    total_pemilik = db.session.query(func.count(PemilikHewan.id_pemilik)).scalar()
    total_hewan = db.session.query(func.count(HewanPeliharaan.id_hewan)).scalar()
    total_kunjungan = db.session.query(func.count(Kunjungan.id_kunjungan)).scalar()
    total_pendapatan = db.session.query(func.sum(TagihanKlinik.total_bayar)).scalar() or 0
    
    # Kunjungan hari ini
    today = datetime.now().date()
    kunjungan_hari_ini = db.session.query(func.count(Kunjungan.id_kunjungan)).filter(
        func.date(Kunjungan.tanggal_kunjungan) == today
    ).scalar()
    
    # Vaksinasi yang akan jatuh tempo dalam 7 hari
    future_date = today + timedelta(days=7)
    vaksinasi_jatuh_tempo = db.session.query(JadwalVaksinasi).filter(
        and_(
            JadwalVaksinasi.tanggal_vaksin_berikutnya <= future_date,
            JadwalVaksinasi.tanggal_vaksin_berikutnya >= today
        )
    ).count()
    
    # Obat dengan stok menjipis
    obat_menjipis = db.session.query(func.count(StokObat.id_stok)).filter(
        StokObat.jumlah_stok <= StokObat.stok_minimum * 1.5
    ).scalar()
    
    return render_template('index.html',
                         total_pemilik=total_pemilik,
                         total_hewan=total_hewan,
                         total_kunjungan=total_kunjungan,
                         total_pendapatan=float(total_pendapatan),
                         kunjungan_hari_ini=kunjungan_hari_ini,
                         vaksinasi_jatuh_tempo=vaksinasi_jatuh_tempo,
                         obat_menjipis=obat_menjipis)

# ============================================================================
# ROUTES - PEMILIK HEWAN (CRUD)
# ============================================================================

@app.route('/pemilik', methods=['GET'])
@login_required
def list_pemilik():
    """Daftar pemilik hewan"""
    page = request.args.get('page', 1, type=int)
    search = request.args.get('search', '', type=str)
    
    query = PemilikHewan.query
    if search:
        query = query.filter(or_(
            PemilikHewan.nama_pemilik.ilike(f'%{search}%'),
            PemilikHewan.no_telepon.ilike(f'%{search}%')
        ))
    
    pemilik = query.paginate(page=page, per_page=10)
    return render_template('pemilik/list.html', pemilik=pemilik, search=search)

@app.route('/pemilik/add', methods=['GET', 'POST'])
def add_pemilik():
    """Tambah pemilik hewan"""
    if request.method == 'POST':
        try:
            pemilik = PemilikHewan(
                nama_pemilik=request.form['nama_pemilik'],
                no_telepon=request.form.get('no_telepon'),
                alamat=request.form.get('alamat'),
                email=request.form.get('email')
            )
            db.session.add(pemilik)
            db.session.commit()
            flash('Pemilik hewan berhasil ditambahkan!', 'success')
            return redirect(url_for('list_pemilik'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {str(e)}', 'danger')
    
    return render_template('pemilik/form.html', title='Tambah Pemilik Hewan')

@app.route('/pemilik/<int:id>/edit', methods=['GET', 'POST'])
def edit_pemilik(id):
    """Edit pemilik hewan"""
    pemilik = PemilikHewan.query.get_or_404(id)
    
    if request.method == 'POST':
        try:
            pemilik.nama_pemilik = request.form['nama_pemilik']
            pemilik.no_telepon = request.form.get('no_telepon')
            pemilik.alamat = request.form.get('alamat')
            pemilik.email = request.form.get('email')
            
            db.session.commit()
            flash('Pemilik hewan berhasil diperbarui!', 'success')
            return redirect(url_for('list_pemilik'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {str(e)}', 'danger')
    
    return render_template('pemilik/form.html', pemilik=pemilik, title='Edit Pemilik Hewan')

@app.route('/pemilik/<int:id>/delete', methods=['POST'])
def delete_pemilik(id):
    """Hapus pemilik hewan"""
    pemilik = PemilikHewan.query.get_or_404(id)
    
    try:
        db.session.delete(pemilik)
        db.session.commit()
        flash('Pemilik hewan berhasil dihapus!', 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'Error: {str(e)}', 'danger')
    
    return redirect(url_for('list_pemilik'))

# ============================================================================
# ROUTES - HEWAN PELIHARAAN (CRUD)
# ============================================================================

@app.route('/hewan', methods=['GET'])
def list_hewan():
    """Daftar hewan peliharaan"""
    page = request.args.get('page', 1, type=int)
    search = request.args.get('search', '', type=str)
    
    query = HewanPeliharaan.query
    if search:
        query = query.join(HewanPeliharaan.pemilik).filter(or_(
            HewanPeliharaan.nama_hewan.ilike(f'%{search}%'),
            PemilikHewan.nama_pemilik.ilike(f'%{search}%')
        ))
    
    hewan = query.paginate(page=page, per_page=10)
    return render_template('hewan/list.html', hewan=hewan, search=search)

@app.route('/hewan/add', methods=['GET', 'POST'])
def add_hewan():
    """Tambah hewan peliharaan"""
    if request.method == 'POST':
        try:
            hewan = HewanPeliharaan(
                id_pemilik=request.form['id_pemilik'],
                id_jenis=request.form['id_jenis'],
                id_ras=request.form['id_ras'],
                nama_hewan=request.form['nama_hewan'],
                jenis_kelamin=request.form.get('jenis_kelamin'),
                tanggal_lahir=request.form.get('tanggal_lahir') or None,
                berat_kg=request.form.get('berat_kg') or None
            )
            db.session.add(hewan)
            db.session.commit()
            flash('Hewan peliharaan berhasil ditambahkan!', 'success')
            return redirect(url_for('list_hewan'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {str(e)}', 'danger')
    
    pemilik = PemilikHewan.query.all()
    jenis = JenisHewan.query.all()
    return render_template('hewan/form.html', pemilik=pemilik, jenis=jenis, title='Tambah Hewan Peliharaan')

@app.route('/hewan/<int:id>/detail')
def detail_hewan(id):
    """Detail hewan peliharaan"""
    hewan = HewanPeliharaan.query.get_or_404(id)
    kunjungan = Kunjungan.query.filter_by(id_hewan=id).order_by(desc(Kunjungan.tanggal_kunjungan)).limit(5).all()
    jadwal_vaksinasi = JadwalVaksinasi.query.filter_by(id_hewan=id).all()
    
    return render_template('hewan/detail.html', hewan=hewan, kunjungan=kunjungan, jadwal_vaksinasi=jadwal_vaksinasi)

@app.route('/hewan/<int:id>/edit', methods=['GET', 'POST'])
def edit_hewan(id):
    """Edit hewan peliharaan"""
    hewan = HewanPeliharaan.query.get_or_404(id)
    
    if request.method == 'POST':
        try:
            hewan.nama_hewan = request.form['nama_hewan']
            hewan.jenis_kelamin = request.form.get('jenis_kelamin')
            hewan.tanggal_lahir = request.form.get('tanggal_lahir') or None
            hewan.berat_kg = request.form.get('berat_kg') or None
            
            db.session.commit()
            flash('Hewan peliharaan berhasil diperbarui!', 'success')
            return redirect(url_for('detail_hewan', id=id))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {str(e)}', 'danger')
    
    return render_template('hewan/form_edit.html', hewan=hewan, title='Edit Hewan Peliharaan')

@app.route('/hewan/<int:id>/delete', methods=['POST'])
def delete_hewan(id):
    """Hapus hewan peliharaan"""
    hewan = HewanPeliharaan.query.get_or_404(id)
    id_pemilik = hewan.id_pemilik
    
    try:
        db.session.delete(hewan)
        db.session.commit()
        flash('Hewan peliharaan berhasil dihapus!', 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'Error: {str(e)}', 'danger')
    
    return redirect(url_for('detail_pemilik', id=id_pemilik))

# ============================================================================
# ROUTES - KUNJUNGAN & REKAM MEDIS (CRUD)
# ============================================================================

@app.route('/kunjungan', methods=['GET'])
def list_kunjungan():
    """Daftar kunjungan"""
    page = request.args.get('page', 1, type=int)
    search = request.args.get('search', '', type=str)
    
    query = Kunjungan.query
    if search:
        query = query.join(Kunjungan.hewan).filter(
            HewanPeliharaan.nama_hewan.ilike(f'%{search}%')
        )
    
    kunjungan = query.order_by(desc(Kunjungan.tanggal_kunjungan)).paginate(page=page, per_page=10)
    return render_template('kunjungan/list.html', kunjungan=kunjungan, search=search)

@app.route('/kunjungan/add', methods=['GET', 'POST'])
def add_kunjungan():
    """Tambah kunjungan"""
    if request.method == 'POST':
        try:
            kunjungan = Kunjungan(
                id_hewan=request.form['id_hewan'],
                id_dokter=request.form['id_dokter'],
                keluhan=request.form.get('keluhan'),
                diagnosa=request.form.get('diagnosa'),
                catatan_dokter=request.form.get('catatan_dokter')
            )
            db.session.add(kunjungan)
            db.session.commit()
            
            # Buat tagihan otomatis
            tagihan = TagihanKlinik(
                id_kunjungan=kunjungan.id_kunjungan,
                id_hewan=kunjungan.id_hewan,
                id_pemilik=kunjungan.hewan.id_pemilik,
                status_pembayaran='Belum Bayar'
            )
            db.session.add(tagihan)
            db.session.commit()
            
            flash('Kunjungan berhasil ditambahkan!', 'success')
            return redirect(url_for('detail_kunjungan', id=kunjungan.id_kunjungan))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {str(e)}', 'danger')
    
    hewan = HewanPeliharaan.query.all()
    dokter = DokterHewan.query.filter_by(status=True).all()
    return render_template('kunjungan/form.html', hewan=hewan, dokter=dokter, title='Tambah Kunjungan')

@app.route('/kunjungan/<int:id>/detail')
def detail_kunjungan(id):
    """Detail kunjungan"""
    kunjungan = Kunjungan.query.get_or_404(id)
    return render_template('kunjungan/detail.html', kunjungan=kunjungan)

# ============================================================================
# ROUTES - RESEP & OBAT
# ============================================================================

@app.route('/obat', methods=['GET'])
def list_obat():
    """Daftar obat"""
    obat = JenisObat.query.all()
    return render_template('obat/list.html', obat=obat)

@app.route('/obat/stok-menjipis', methods=['GET'])
def stok_menjipis():
    """Obat dengan stok menjipis"""
    obat_menjipis = db.session.query(JenisObat, StokObat).join(
        StokObat, JenisObat.id_obat == StokObat.id_obat
    ).filter(
        StokObat.jumlah_stok <= StokObat.stok_minimum * 1.5
    ).all()
    
    return render_template('obat/stok_menjipis.html', obat_menjipis=obat_menjipis)

# ============================================================================
# ROUTES - VAKSINASI
# ============================================================================

@app.route('/vaksinasi/jadwal-akan-jatuh-tempo', methods=['GET'])
def vaksinasi_akan_jatuh_tempo():
    """Hewan yang akan jatuh tempo vaksinasi dalam 7 hari"""
    today = datetime.now().date()
    future_date = today + timedelta(days=7)
    
    jadwal = JadwalVaksinasi.query.filter(
        and_(
            JadwalVaksinasi.tanggal_vaksin_berikutnya <= future_date,
            JadwalVaksinasi.tanggal_vaksin_berikutnya >= today,
            JadwalVaksinasi.status_vaksinasi == 'Belum Vaksin'
        )
    ).all()
    
    return render_template('vaksinasi/akan_jatuh_tempo.html', jadwal=jadwal)

# ============================================================================
# ROUTES - LAPORAN
# ============================================================================

@app.route('/laporan/pendapatan')
def laporan_pendapatan():
    """Laporan pendapatan klinik"""
    # Query untuk pendapatan per bulan per jenis layanan
    results = db.session.execute(text("""
        SELECT 
            TO_CHAR(k.tanggal_kunjungan, 'YYYY-MM') AS bulan,
            jtm.nama_tindakan,
            COUNT(*) AS jumlah_kunjungan,
            COALESCE(SUM(tmk.harga_tindakan * tmk.jumlah), 0) AS total_pendapatan
        FROM kunjungan k
        LEFT JOIN tindakan_medis_kunjungan tmk ON k.id_kunjungan = tmk.id_kunjungan
        LEFT JOIN jenis_tindakan_medis jtm ON tmk.id_tindakan = jtm.id_tindakan
        GROUP BY TO_CHAR(k.tanggal_kunjungan, 'YYYY-MM'), jtm.nama_tindakan
        ORDER BY bulan DESC, total_pendapatan DESC
    """)).fetchall()
    
    return render_template('laporan/pendapatan.html', results=results)

@app.route('/laporan/jenis-hewan-terbanyak')
def laporan_jenis_hewan_terbanyak():
    """Laporan jenis hewan paling banyak ditangani"""
    results = db.session.execute(text("""
        SELECT 
            jh.nama_jenis,
            COUNT(*) AS jumlah_kunjungan,
            COUNT(DISTINCT k.id_hewan) AS jumlah_hewan
        FROM kunjungan k
        JOIN hewan_peliharaan hp ON k.id_hewan = hp.id_hewan
        JOIN jenis_hewan jh ON hp.id_jenis = jh.id_jenis
        GROUP BY jh.nama_jenis
        ORDER BY jumlah_kunjungan DESC
    """)).fetchall()
    
    return render_template('laporan/jenis_hewan.html', results=results)

@app.route('/laporan/tren-kunjungan')
def laporan_tren_kunjungan():
    """Laporan tren kunjungan harian dalam 1 bulan terakhir"""
    results = db.session.execute(text("""
        SELECT 
            DATE(k.tanggal_kunjungan) AS tanggal_kunjungan,
            COUNT(*) AS jumlah_kunjungan,
            COUNT(DISTINCT k.id_hewan) AS jumlah_hewan_unik
        FROM kunjungan k
        WHERE k.tanggal_kunjungan >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY DATE(k.tanggal_kunjungan)
        ORDER BY tanggal_kunjungan DESC
    """)).fetchall()
    
    return render_template('laporan/tren_kunjungan.html', results=results)

@app.route('/laporan/dokter-terbanyak-kunjungan')
def laporan_dokter_terbanyak():
    """Laporan dokter dengan kunjungan terbanyak"""
    results = db.session.execute(text("""
        SELECT 
            dh.id_dokter,
            dh.nama_dokter,
            s.nama_spesialisasi,
            COUNT(*) AS jumlah_kunjungan
        FROM kunjungan k
        JOIN dokter_hewan dh ON k.id_dokter = dh.id_dokter
        JOIN spesialisasi s ON dh.id_spesialisasi = s.id_spesialisasi
        GROUP BY dh.id_dokter, dh.nama_dokter, s.nama_spesialisasi
        ORDER BY jumlah_kunjungan DESC
    """)).fetchall()
    
    return render_template('laporan/dokter_terbanyak.html', results=results)

@app.route('/laporan/obat-paling-sering-diresepkan')
def laporan_obat_sering():
    """Laporan obat paling sering diresepkan"""
    results = db.session.execute(text("""
        SELECT 
            oh.nama_obat,
            oh.jenis_obat,
            COUNT(*) AS jumlah_resep,
            SUM(rh.jumlah_obat) AS total_jumlah,
            COALESCE(SUM(oh.harga_satuan * rh.jumlah_obat), 0) AS total_nilai
        FROM resep_hewan rh
        JOIN obat_hewan oh ON rh.id_obat = oh.id_obat
        GROUP BY oh.id_obat, oh.nama_obat, oh.jenis_obat
        ORDER BY jumlah_resep DESC
    """)).fetchall()
    
    return render_template('laporan/obat_sering.html', results=results)

# ============================================================================
# HELPER ROUTES
# ============================================================================

@app.route('/api/ras/<int:id_jenis>')
def get_ras_by_jenis(id_jenis):
    """API untuk get ras berdasarkan jenis"""
    ras = RasHewan.query.filter_by(id_jenis=id_jenis).all()
    return jsonify([{'id_ras': r.id_ras, 'nama_ras': r.nama_ras} for r in ras])

@app.route('/pemilik/<int:id>/detail')
def detail_pemilik(id):
    """Detail pemilik hewan"""
    pemilik = PemilikHewan.query.get_or_404(id)
    return render_template('pemilik/detail.html', pemilik=pemilik)

# ============================================================================
# ERROR HANDLERS
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    return render_template('errors/404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return render_template('errors/500.html'), 500

# ============================================================================
# CONTEXT PROCESSORS
# ============================================================================

@app.context_processor
def utility_processor():
    def currency(value):
        try:
            return f"Rp {float(value):,.0f}"
        except:
            return "Rp 0"
    return dict(currency=currency)

# ============================================================================
# MAIN APP
# ============================================================================

if __name__ == '__main__':
    app.run(debug=True, port=5001)
