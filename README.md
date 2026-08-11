# 🎨 Paint Machine Maintenance — Boya Makinesi Bakım & Yönetim Sistemi

[![.NET Version](https://img.shields.io/badge/.NET-8.0-blue.svg)](https://dotnet.microsoft.com/)
[![Database](https://img.shields.io/badge/PostgreSQL-10%2B-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

> **[TR]** Türkçe açıklama için [aşağıya kaydırın](#-türkçe).  
> **[EN]** Scroll down for the [English documentation](#-english).

---

<a name="-türkçe"></a>
## 🇹🇷 Türkçe

Bu proje, boya makinelerinin bakım kayıtlarını takip etmek, boya karışımları hazırlamak, hazne stoklarını yönetmek ve dükkan/personel rollerini PostgreSQL altyapısıyla yönetmek için geliştirilmiş modern bir **C# Windows Forms (.NET 8.0)** uygulamasıdır.

### 📁 Proje Yapısı

```
paint-machine-maintenance/
├── src/
│   └── PaintMachineMaintenance/
│       ├── AnaForm.cs              # Ana yönetim ve bakım uyarı ekranı
│       ├── BoyaYap.cs              # Boya karıştırma & müşteri sipariş ekranı
│       ├── DukkanEkleForm.cs       # Dükkan ekleme ve yönetimi
│       ├── GecmisForm.cs           # Müşteri geçmişi ve sipariş raporları
│       ├── hazneler.cs             # Pigment hazne stok yönetimi
│       ├── LogForm.cs              # Bakım ve sistem logları
│       ├── RolEkleForm.cs          # Personel ve rol yönetimi
│       ├── DatabaseHelper.cs       # PostgreSQL bağlantı yöneticisi
│       └── PaintMachineMaintenance.csproj
├── sql/
│   └── proje.sql                   # Veritabanı şeması, tablolar ve saklı yordamlar (UTF-8)
├── PaintMachineMaintenance.sln     # Visual Studio Solution dosyası
└── README.md
```

### 🛠️ Gereksinimler

- **İşletim Sistemi:** Windows
- **Çalışma Zamanı / SDK:** .NET 8.0 SDK (veya üstü)
- **Veritabanı:** PostgreSQL 10+ (Port: 5432, Veritabanı Adı: `boyamakinedevami`)
- **IDE:** Visual Studio 2022+ / Visual Studio Code / Rider veya .NET CLI (`dotnet`)

### 🚀 Kurulum ve Çalıştırma

#### 1. PostgreSQL Veritabanı Kurulumu

PostgreSQL ortamınızda veritabanını oluşturun ve `sql/proje.sql` dosyasını içe aktarın:

```bash
# Veritabanını oluşturun
psql -U postgres -c "CREATE DATABASE boyamakinedevami;"

# Şema, fonksiyonlar ve başlangıç verilerini aktarın
psql -U postgres -d boyamakinedevami -f sql/proje.sql
```

> **Not:** Varsayılan veritabanı ayarları:
> - **Host:** `localhost` | **Port:** `5432` | **Database:** `boyamakinedevami` | **Username:** `postgres` | **Password:** `admin`
> 
> Bağlantı bilgilerini `src/PaintMachineMaintenance/DatabaseHelper.cs` dosyasından güncelleyebilirsiniz.

#### 2. Derleme ve Çalıştırma

Terminal üzerinden çalıştırmak için:

```bash
# Bağımlılıkları geri yükleyin ve derleyin
dotnet build

# Uygulamayı başlatın
dotnet run --project src/PaintMachineMaintenance/PaintMachineMaintenance.csproj
```

### 📌 Özellikler

- 🔧 **Bakım Uyarı Sistemi:** Makine parçalarının (Karıştırıcı Motor, Boya Pompası, Filtre Sistemi) bakım sürelerini otomatik hesaplar ve KRİTİK / GECİKMİŞ durumlarını renklendirerek uyarır.
- 🎨 **Boya Karışım Yönetimi:** Renk kodlarına göre pigment miktarlarını hesaplar, stokları otomatik düşer ve müşteri siparişini kaydeder.
- 🧪 **Hazne & Stok Takibi:** Pigment haznelerinin doluluk oranlarını görsel progress bar'lar ile takip eder, stok ekleme/çıkarma işlemlerini yönetir.
- 🏪 **Dükkan & Personel Yönetimi:** Dükkan ekleme/silme ve personele özel rol (Boya Ustası, Müdür vb.) ataması sağlar.
- 📜 **Geçmiş & Loglar:** Müşteri sipariş geçmişi ve sistem bakım kayıtlarını detaylı listeler.

---

<a name="-english"></a>
## 🇬🇧 English

This project is a modern **C# Windows Forms (.NET 8.0)** desktop application powered by a **PostgreSQL** backend, designed to manage paint machine maintenance, track color mixing recipes, monitor pigment inventory canisters, and manage multi-store staff roles.

### 📁 Project Structure

```
paint-machine-maintenance/
├── src/
│   └── PaintMachineMaintenance/
│       ├── AnaForm.cs              # Main dashboard & maintenance alert view
│       ├── BoyaYap.cs              # Paint mixing & order processing form
│       ├── DukkanEkleForm.cs       # Store management interface
│       ├── GecmisForm.cs           # Customer history & order reporting
│       ├── hazneler.cs             # Canister inventory management
│       ├── LogForm.cs              # Maintenance & system logs
│       ├── RolEkleForm.cs          # Staff & role assignment
│       ├── DatabaseHelper.cs       # PostgreSQL connection manager
│       └── PaintMachineMaintenance.csproj
├── sql/
│   └── proje.sql                   # Database schema, tables, and stored functions (UTF-8)
├── PaintMachineMaintenance.sln     # Visual Studio Solution file
└── README.md
```

### 🛠️ Requirements

- **Operating System:** Windows
- **Runtime / SDK:** .NET 8.0 SDK (or later)
- **Database:** PostgreSQL 10+ (Port: 5432, Database Name: `boyamakinedevami`)
- **IDE:** Visual Studio 2022+ / Visual Studio Code / Rider or .NET CLI (`dotnet`)

### 🚀 Setup & Run

#### 1. PostgreSQL Database Setup

Create the database in PostgreSQL and import `sql/proje.sql`:

```bash
# Create database
psql -U postgres -c "CREATE DATABASE boyamakinedevami;"

# Import schema, stored functions, and initial seed data
psql -U postgres -d boyamakinedevami -f sql/proje.sql
```

> **Note:** Default database credentials:
> - **Host:** `localhost` | **Port:** `5432` | **Database:** `boyamakinedevami` | **Username:** `postgres` | **Password:** `admin`
> 
> Connection parameters can be updated in `src/PaintMachineMaintenance/DatabaseHelper.cs`.

#### 2. Build & Execute

To build and run from CLI:

```bash
# Restore packages & build
dotnet build

# Run application
dotnet run --project src/PaintMachineMaintenance/PaintMachineMaintenance.csproj
```

Or open `PaintMachineMaintenance.sln` in Visual Studio 2022 and press **F5**.

### 📌 Features

- 🔧 **Maintenance Alerts:** Calculates component service intervals (Mixer Motor, Paint Pump, Filter System) and provides color-coded CRITICAL / OVERDUE warnings.
- 🎨 **Paint Recipe Mixing:** Calculates exact pigment breakdown per color code, auto-deducts stock, and records customer orders.
- 🧪 **Canister Inventory Tracking:** Displays pigment canister fill levels using visual progress bars with add/remove stock management.
- 🏪 **Store & Staff Management:** Add/delete store locations and assign custom staff roles (Paint Master, Manager, etc.).
- 📜 **History & Logs:** Provides complete audit trail of customer purchase history and machine maintenance records.

---

## 👤 Author & License

- **Author:** Abdülsamet Akan
- **License:** [MIT](https://opensource.org/licenses/MIT)