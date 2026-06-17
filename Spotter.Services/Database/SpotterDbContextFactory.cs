using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Spotter.Services.Database
{
    public class SpotterDbContextFactory : IDesignTimeDbContextFactory<SpotterDbContext>
    {
        public SpotterDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<SpotterDbContext>();

            var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
                ?? Environment.GetEnvironmentVariable("SPOTTER_CONNECTION_STRING")
                ?? throw new InvalidOperationException("Set ConnectionStrings__DefaultConnection or SPOTTER_CONNECTION_STRING before running EF design-time commands.");

            optionsBuilder.UseSqlServer(connectionString);
            return new SpotterDbContext(optionsBuilder.Options);
        }
    }
}
