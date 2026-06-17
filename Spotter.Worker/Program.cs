using Microsoft.EntityFrameworkCore;
using Spotter.Worker.Consumers;
using Spotter.Worker.Data;
using Spotter.Worker.RabbitMq;
using Spotter.Worker.Services;

DotNetEnv.Env.TraversePath().Load();

var host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        services.AddDbContext<WorkerDbContext>(options =>
            options.UseSqlServer(
                Environment.GetEnvironmentVariable("SPOTTER_CONNECTION_STRING")
                ?? throw new InvalidOperationException("SPOTTER_CONNECTION_STRING not set.")));

        services.AddHttpClient();
        services.AddSingleton<IRabbitMqConnectionFactory, RabbitMqConnectionFactory>();
        services.AddScoped<IGeocodingService, GeocodingService>();
        services.AddScoped<IEmailService, EmailService>();
        services.AddHostedService<GeocodingConsumer>();
        services.AddHostedService<EmailConsumer>();
    })
    .Build();

await host.RunAsync();
