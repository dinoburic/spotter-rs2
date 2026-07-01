using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Spotter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddSystemSettingDescription : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "SystemSettings",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "Description", "Key" },
                values: new object[] { "Application name", "App.Name" });

            migrationBuilder.UpdateData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "Description", "Key" },
                values: new object[] { "Default currency", "App.Currency" });

            migrationBuilder.InsertData(
                table: "SystemSettings",
                columns: new[] { "Id", "Description", "Key", "UpdatedAt", "Value" },
                values: new object[,]
                {
                    { 3, "Support email address", "App.SupportEmail", new DateTime(2026, 4, 26, 0, 0, 0, 0, DateTimeKind.Utc), "support@spotter.app" },
                    { 4, "Default timezone", "App.Timezone", new DateTime(2026, 4, 26, 0, 0, 0, 0, DateTimeKind.Utc), "Europe/Sarajevo" },
                    { 5, "Enable email notifications", "Notifications.Email", new DateTime(2026, 4, 26, 0, 0, 0, 0, DateTimeKind.Utc), "true" },
                    { 6, "Low capacity warnings", "Notifications.LowCapacity", new DateTime(2026, 4, 26, 0, 0, 0, 0, DateTimeKind.Utc), "true" },
                    { 7, "New user alerts", "Notifications.NewUser", new DateTime(2026, 4, 26, 0, 0, 0, 0, DateTimeKind.Utc), "true" },
                    { 8, "Event cancellation alerts", "Notifications.EventCancellation", new DateTime(2026, 4, 26, 0, 0, 0, 0, DateTimeKind.Utc), "true" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DropColumn(
                name: "Description",
                table: "SystemSettings");

            migrationBuilder.UpdateData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 1,
                column: "Key",
                value: "AppName");

            migrationBuilder.UpdateData(
                table: "SystemSettings",
                keyColumn: "Id",
                keyValue: 2,
                column: "Key",
                value: "DefaultCurrency");
        }
    }
}
