using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Spotter.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationTicketTypeAndExpiry : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ExpiresAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Quantity",
                table: "Reservations",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "TicketTypeId",
                table: "Reservations",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_TicketTypeId",
                table: "Reservations",
                column: "TicketTypeId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_TicketTypes_TicketTypeId",
                table: "Reservations",
                column: "TicketTypeId",
                principalTable: "TicketTypes",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_TicketTypes_TicketTypeId",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_TicketTypeId",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "ExpiresAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "Quantity",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "TicketTypeId",
                table: "Reservations");
        }
    }
}
