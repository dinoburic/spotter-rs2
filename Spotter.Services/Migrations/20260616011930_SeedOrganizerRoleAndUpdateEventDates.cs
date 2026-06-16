using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Spotter.Services.Migrations
{
    /// <inheritdoc />
    public partial class SeedOrganizerRoleAndUpdateEventDates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 7, 15, 23, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 7, 15, 20, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 8, 20, 14, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 8, 20, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 9, 1, 22, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 9, 1, 19, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 10, 25, 17, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 10, 25, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 11, 30, 20, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 11, 30, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 12, 22, 23, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 12, 22, 20, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.InsertData(
                table: "Roles",
                columns: new[] { "Id", "CreatedAt", "Description", "IsActive", "Name" },
                values: new object[] { 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Event organizer", true, "Organizer" });

            migrationBuilder.UpdateData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "DateAssigned", "RoleId" },
                values: new object[] { new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 3 });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Roles",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 5, 15, 23, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 15, 20, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 5, 20, 14, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 20, 8, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 6, 1, 22, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 6, 1, 19, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 5, 25, 17, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 25, 10, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 5, 30, 20, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 30, 12, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "EndsAt", "StartsAt" },
                values: new object[] { new DateTime(2026, 5, 22, 23, 0, 0, 0, DateTimeKind.Utc), new DateTime(2026, 5, 22, 20, 0, 0, 0, DateTimeKind.Utc) });

            migrationBuilder.UpdateData(
                table: "UserRoles",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "DateAssigned", "RoleId" },
                values: new object[] { new DateTime(2026, 4, 26, 0, 0, 0, 0, DateTimeKind.Utc), 2 });
        }
    }
}
