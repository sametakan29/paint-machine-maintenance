using System;
using Npgsql;

namespace PaintMachineMaintenance
{
    public static class DatabaseHelper
    {
        // Bağlantı bilgileri (Varsayılan PostgreSQL ayarları)
        public static string Host { get; set; } = "localhost";
        public static string Port { get; set; } = "5432";
        public static string Database { get; set; } = "boyamakinedevami";
        public static string Username { get; set; } = "postgres"; 
        public static string Password { get; set; } = "admin";  

        public static string ConnectionString =>
            $"Host={Host};Port={Port};Database={Database};Username={Username};Password={Password};Include Error Detail=true;";

        /// <summary>
        /// Yeni bir PostgreSQL bağlantısı oluşturur
        /// </summary>
        public static NpgsqlConnection GetConnection()
        {
            return new NpgsqlConnection(ConnectionString);
        }

        /// <summary>
        /// Veritabanı bağlantısını test eder
        /// </summary>
        public static bool TestConnection(out string errorMessage)
        {
            errorMessage = string.Empty;
            try
            {
                using (var connection = GetConnection())
                {
                    connection.Open();
                    return true;
                }
            }
            catch (Exception ex)
            {
                errorMessage = ex.Message;
                return false;
            }
        }
    }
}
