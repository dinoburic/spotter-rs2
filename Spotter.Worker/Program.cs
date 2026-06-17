using Microsoft.EntityFrameworkCore;
using Spotter.Worker.Consumers;
using Spotter.Worker.Data;
using Spotter.Worker.RabbitMq;
using Spotter.Worker.Services;

if (!string.Equals(Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER"), "true", StringComparison.OrdinalIgnoreCase))
{
    DotNetEnv.Env.TraversePath().Load();
}

var host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        var configuredConnectionString = context.Configuration.GetConnectionString("DefaultConnection");
        var connectionString = !string.IsNullOrWhiteSpace(configuredConnectionString)
            ? configuredConnectionString
            : Environment.GetEnvironmentVariable("SPOTTER_CONNECTION_STRING");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException("Database connection string not configured.");
        }

        services.AddDbContext<WorkerDbContext>(options =>
            options.UseSqlServer(connectionString));

        services.AddHttpClient("Geocoding", client =>
        {
            client.Timeout = TimeSpan.FromSeconds(10);
        });
        services.AddSingleton<IRabbitMqConnectionFactory, RabbitMqConnectionFactory>();
        services.AddScoped<IGeocodingService, GeocodingService>();
        services.AddScoped<IEmailService, EmailService>();
        services.AddHostedService<GeocodingConsumer>();
        services.AddHostedService<EmailConsumer>();
    })
    .Build();

await host.RunAsync();
