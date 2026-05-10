# Paint Machine Maintenance — Assignment

This project is a Windows Forms application written in C# with a PostgreSQL backend. It was created as a database management systems assignment to track maintenance records, paint mixing, and role-based access for paint machines across multiple store locations.

- **Course:** Fall 2025

## Contents

```
paint-machine-maintenance/
├── dneme1/
│   ├── dneme1/
│   │   ├── AnaForm.cs              # Main application form
│   │   ├── BoyaYap.cs              # Paint mixing management
│   │   ├── DukkanEkleForm.cs       # Store/location management
│   │   ├── GecmisForm.cs           # History and reports
│   │   ├── hazneler.cs             # Hazardous materials management
│   │   ├── LogForm.cs              # Logging interface
│   │   ├── RolEkleForm.cs          # Role management
│   │   ├── DatabaseHelper.cs       # Database connection utilities
│   │   └── App.config              # Application configuration
│   └── dneme1.sln                  # Visual Studio solution file
└── sql/
    └── proje.sql                   # PostgreSQL database schema and functions
```

## Requirements

- Windows
- .NET Framework 4.8.1
- PostgreSQL 10+
- Visual Studio 2019 or later with the Windows Forms workload
- Npgsql 4.1.14 (restored automatically via NuGet)

## Build & Run

### 1. Database setup

Create the database and import the schema:

```bash
psql -U postgres -c "CREATE DATABASE boyamakinedevami;"
psql -U postgres -d boyamakinedevami -f sql/proje.sql
```

### 2. Application setup

1. Open `dneme1/dneme1.sln` in Visual Studio.
2. Restore NuGet packages.
3. Update the connection credentials in `DatabaseHelper.cs` if needed.
4. Build and run (F5 or Ctrl+F5).

Or build from the command line:

```bash
msbuild dneme1/dneme1.sln /p:Configuration=Release
```

## Usage

The main form (`AnaForm`) provides access to all modules:

- Record and track maintenance activities per machine and store
- Manage store locations and user roles
- Track paint color mixing and material usage
- View maintenance history and system logs
- Receive automatic alerts for overdue maintenance tasks

## Notes

- This is an educational example and kept intentionally simple.
- Database credentials are hardcoded in `DatabaseHelper.cs` — do not commit real passwords to version control.
- The PostgreSQL function `bakim_uyarilari()` handles maintenance alert generation.

## Author

Abdülsamet Akan

## License

[MIT](https://opensource.org/licenses/MIT)