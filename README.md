# Paint Machine Maintenance (Boya Makinesi Bakım & Yönetim Sistemi)

Bu proje, boya makinelerinin bakım kayıtlarını takip etmek, boya karışımları hazırlamak, hazne stoklarını yönetmek ve dükkan/personel rollerini PostgreSQL altyapısıyla yönetmek için geliştirilmiş modern bir **C# Windows Forms (.NET 8.0)** uygulamasıdır.

---

## 📁 Proje Yapısı

```
paint-machine-maintenance-main/
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

---

## 🛠️ Gereksinimler

- **İşletim Sistemi:** Windows
- **Çalışma Zamanı / SDK:** .NET 8.0 SDK (veya üstü)
- **Veritabanı:** PostgreSQL 10+ (Port: 5432, Veritabanı Adı: `boyamakinedevami`)
- **IDE:** Visual Studio 2022+ / Visual Studio Code / Rider veya .NET CLI (`dotnet`)

---

## 🚀 Kurulum ve Çalıştırma

### 1. PostgreSQL Veritabanı Kurulumu

PostgreSQL ortamınızda veritabanını oluşturun ve `sql/proje.sql` dosyasını içe aktarın:

```bash
# Veritabanını oluşturun
psql -U postgres -c "CREATE DATABASE boyamakinedevami;"

# Şema, fonksiyonlar ve başlangıç verilerini aktarın
psql -U postgres -d boyamakinedevami -f sql/proje.sql
```

> **Not:** Varsayılan veritabanı ayarları:
> - **Host:** `localhost`
> - **Port:** `5432`
> - **Database:** `boyamakinedevami`
> - **Username:** `postgres`
> - **Password:** `admin`
> 
> Farklı bir şifre veya bağlantı bilgisi kullanıyorsanız `src/PaintMachineMaintenance/DatabaseHelper.cs` dosyasından güncelleyebilirsiniz.

### 2. Derleme ve Çalıştırma

Terminal üzerinden çalıştırmak için:

```bash
# Bağımlılıkları geri yükleyin ve derleyin
dotnet build

# Uygulamayı başlatın
dotnet run --project src/PaintMachineMaintenance/PaintMachineMaintenance.csproj
```

Veya `PaintMachineMaintenance.sln` dosyasını Visual Studio 2022 ile açıp `F5` tuşuna basarak çalıştırabilirsiniz.

---

## 📌 Özellikler

- 🔧 **Bakım Uyarı Sistemi:** Makine parçalarının (Karıştırıcı Motor, Boya Pompası, Filtre Sistemi) bakım sürelerini otomatik hesaplar ve KRİTİK / GECİKMİŞ durumlarını renklendirerek uyarır.
- 🎨 **Boya Karışım Yönetimi:** Renk kodlarına göre pigment miktarlarını hesaplar, stokları otomatik düşer ve müşteri siparişini kaydeder.
- 🧪 **Hazne & Stok Takibi:** Pigment haznelerinin doluluk oranlarını görsel progress bar'lar ile takip eder, stok ekleme/çıkarma işlemlerini yönetir.
- 🏪 **Dükkan & Personel Yönetimi:** Dükkan ekleme/silme ve personele özel rol (Boya Ustası, Müdür vb.) ataması sağlar.
- 📜 **Geçmiş & Loglar:** Müşteri sipariş geçmişi ve sistem bakım kayıtlarını detaylı listeler.

---

## 👤 Yazar & Lisans

- **Geliştirici:** Abdülsamet Akan
- **Lisans:** MIT