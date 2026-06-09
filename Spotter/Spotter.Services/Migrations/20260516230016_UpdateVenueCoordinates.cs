using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Spotter.Services.Migrations
{
    /// <inheritdoc />
    public partial class UpdateVenueCoordinates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("UPDATE Venues SET Latitude = 43.8563, Longitude = 18.4131, GeocodingPending = 0 WHERE Id = 1");
            migrationBuilder.Sql("UPDATE Venues SET Latitude = 43.3438, Longitude = 17.8078, GeocodingPending = 0 WHERE Id = 2");
            migrationBuilder.Sql("UPDATE Venues SET Latitude = 44.7722, Longitude = 17.1910, GeocodingPending = 0 WHERE Id = 3");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("UPDATE Venues SET Latitude = NULL, Longitude = NULL, GeocodingPending = 1 WHERE Id IN (1, 2, 3)");
        }
    }
}
