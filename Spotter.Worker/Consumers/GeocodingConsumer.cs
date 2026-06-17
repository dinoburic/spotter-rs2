using System.Text;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using Spotter.Model.Messages;
using Spotter.Worker.Data;
using Spotter.Worker.RabbitMq;
using Spotter.Worker.Services;

namespace Spotter.Worker.Consumers
{
    public class GeocodingConsumer : BackgroundService
    {
        private const int MaxRetryCount = 3;
        private readonly IRabbitMqConnectionFactory _connectionFactory;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<GeocodingConsumer> _logger;
        private IConnection? _connection;
        private IChannel? _channel;

        public GeocodingConsumer(
            IRabbitMqConnectionFactory connectionFactory,
            IServiceProvider serviceProvider,
            ILogger<GeocodingConsumer> logger)
        {
            _connectionFactory = connectionFactory;
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    _logger.LogInformation("GeocodingConsumer starting");
                    _connection = await _connectionFactory.CreateConnectionAsync();
                    _channel = await _connection.CreateChannelAsync();

                    await _channel.QueueDeclareAsync(
                        queue: QueueNames.Geocoding,
                        durable: true,
                        exclusive: false,
                        autoDelete: false);

                    await _channel.QueueDeclareAsync(
                        queue: QueueNames.GeocodingDlq,
                        durable: true,
                        exclusive: false,
                        autoDelete: false);

                    var consumer = new AsyncEventingBasicConsumer(_channel);
                    consumer.ReceivedAsync += async (_, ea) =>
                    {
                        var body = ea.Body.ToArray();
                        var json = Encoding.UTF8.GetString(body);
                        var message = JsonConvert.DeserializeObject<GeocodingRequestMessage>(json);

                        _logger.LogInformation("GeocodingConsumer received message for venue {VenueId}", message?.VenueId);

                        if (message == null)
                        {
                            await _channel.BasicAckAsync(ea.DeliveryTag, false);
                            return;
                        }

                        try
                        {
                            using var scope = _serviceProvider.CreateScope();
                            var geocodingService = scope.ServiceProvider.GetRequiredService<IGeocodingService>();
                            var dbContext = scope.ServiceProvider.GetRequiredService<WorkerDbContext>();

                            var result = await geocodingService.GeocodeAsync(message.Name, message.Address, message.City, message.Country);

                            var venue = await dbContext.Venues.FirstOrDefaultAsync(v => v.Id == message.VenueId, stoppingToken);
                            if (venue != null)
                            {
                                if (result.HasValue)
                                {
                                    venue.Latitude = result.Value.Latitude;
                                    venue.Longitude = result.Value.Longitude;
                                    _logger.LogInformation("Geocoded venue {VenueId}: {Lat}, {Lng}", message.VenueId, result.Value.Latitude, result.Value.Longitude);
                                }
                                else
                                {
                                    _logger.LogWarning("Geocoding failed for venue {VenueId}", message.VenueId);
                                }

                                venue.GeocodingPending = false;
                                await dbContext.SaveChangesAsync(stoppingToken);
                            }

                            await _channel.BasicAckAsync(ea.DeliveryTag, false);
                        }
                        catch (Exception ex)
                        {
                            var retryCount = GetRetryCount(ea.BasicProperties);
                            if (retryCount >= MaxRetryCount)
                            {
                                _logger.LogError(ex, "Message discarded after {MaxRetries} retries for venue {VenueId}. Publishing to DLQ.", MaxRetryCount, message?.VenueId);
                                var dlqProperties = new BasicProperties
                                {
                                    Headers = ea.BasicProperties.Headers != null
                                        ? new Dictionary<string, object?>(ea.BasicProperties.Headers)
                                        : new Dictionary<string, object?>()
                                };
                                await _channel.BasicPublishAsync(
                                    exchange: "",
                                    routingKey: QueueNames.GeocodingDlq,
                                    mandatory: false,
                                    basicProperties: dlqProperties,
                                    body: ea.Body
                                );
                                await _channel.BasicAckAsync(ea.DeliveryTag, false);
                            }
                            else
                            {
                                var delayMs = (int)Math.Pow(2, retryCount) * 1000;
                                _logger.LogWarning(ex, "Retry {Attempt} for venue {VenueId} after {Delay}ms delay", retryCount + 1, message?.VenueId, delayMs);

                                await Task.Delay(delayMs, stoppingToken);

                                var properties = new BasicProperties
                                {
                                    Headers = new Dictionary<string, object?>
                                    {
                                        ["x-retry-count"] = retryCount + 1
                                    }
                                };
                                await _channel.BasicPublishAsync(
                                    exchange: "",
                                    routingKey: ea.RoutingKey,
                                    mandatory: false,
                                    basicProperties: properties,
                                    body: ea.Body
                                );
                                await _channel.BasicAckAsync(ea.DeliveryTag, false);
                            }
                        }
                    };

                    await _channel.BasicConsumeAsync(QueueNames.Geocoding, autoAck: false, consumer: consumer);
                    _logger.LogInformation("GeocodingConsumer connected and listening");

                    await Task.Delay(Timeout.Infinite, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "GeocodingConsumer failed, retrying in 10 seconds");
                    await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
                }
            }
        }

        private static int GetRetryCount(IReadOnlyBasicProperties properties)
        {
            if (properties.Headers != null &&
                properties.Headers.TryGetValue("x-retry-count", out var retryObj))
            {
                return Convert.ToInt32(retryObj);
            }
            return 0;
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("GeocodingConsumer stopping");
            if (_channel != null) await _channel.CloseAsync();
            if (_connection != null) await _connection.CloseAsync();
            await base.StopAsync(cancellationToken);
        }
    }
}
