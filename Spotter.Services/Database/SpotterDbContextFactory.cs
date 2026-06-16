using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Spotter.Services.Database
{
    public class SpotterDbContextFactory : IDesignTimeDbContextFactory<SpotterDbContext>
    {
        public SpotterDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<SpotterDbContext>();
        
        var connectionString = Environment.GetEnvironmentVariable("SPOTTER_CONNECTION_STRING")
            ?? "Server=localhost,1435;Database=230006;User Id=sa;Password=qweasd123!;TrustServerCertificate=True;";
        
        optionsBuilder.UseSqlServer(connectionString);
        return new SpotterDbContext(optionsBuilder.Options);
        }
    }
}
