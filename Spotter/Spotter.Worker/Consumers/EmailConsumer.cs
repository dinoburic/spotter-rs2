using System.Text;
using Newtonsoft.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using Spotter.Model.Messages;
using Spotter.Worker.RabbitMq;
using Spotter.Worker.Services;

namespace Spotter.Worker.Consumers
{
    public class EmailConsumer : BackgroundService
    {
        private readonly IRabbitMqConnectionFactory _connectionFactory;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<EmailConsumer> _logger;
        private IConnection? _connection;
        private IChannel? _channel;

        public EmailConsumer(
            IRabbitMqConnectionFactory connectionFactory,
            IServiceProvider serviceProvider,
            ILogger<EmailConsumer> logger)
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
                queue: QueueNames.Email,
                durable: true,
                exclusive: false,
                autoDelete: false);

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.ReceivedAsync += async (_, ea) =>
            {
                var body = ea.Body.ToArray();
                var json = Encoding.UTF8.GetString(body);
                var message = JsonConvert.DeserializeObject<EmailMessage>(json);

                if (message == null)
                {
                    await _channel.BasicAckAsync(ea.DeliveryTag, false);
                    return;
                }

                try
                {
                    using var scope = _serviceProvider.CreateScope();
                    var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();
                    await emailService.SendAsync(message);
                    await _channel.BasicAckAsync(ea.DeliveryTag, false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to process email to {To}", message.To);
                    await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: true);
                }
            };

            await _channel.BasicConsumeAsync(QueueNames.Email, autoAck: false, consumer: consumer);
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
        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("EmailConsumer stopping");
            if (_channel != null) await _channel.CloseAsync();
            if (_connection != null) await _connection.CloseAsync();
            await base.StopAsync(cancellationToken);
        }
    }
}
