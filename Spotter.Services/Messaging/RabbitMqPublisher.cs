using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using RabbitMQ.Client;

namespace Spotter.Services
{
    public class RabbitMqPublisher : IRabbitMqPublisher, IDisposable
    {
        private readonly ILogger<RabbitMqPublisher> _logger;
        private readonly string _host;
        private readonly int _port;
        private readonly string _username;
        private readonly string _password;
        private IConnection? _connection;
        private readonly SemaphoreSlim _connectionLock = new(1, 1);

        public RabbitMqPublisher(IConfiguration configuration, ILogger<RabbitMqPublisher> logger)
        {
            _logger = logger;
            _host = configuration["RabbitMQ__Host"] ?? configuration["RabbitMQ:Host"] ?? "localhost";
            _port = int.Parse(configuration["RabbitMQ__Port"] ?? configuration["RabbitMQ:Port"] ?? "5672");
            _username = configuration["RabbitMQ__Username"] ?? configuration["RabbitMQ:Username"] ?? "guest";
            _password = configuration["RabbitMQ__Password"] ?? configuration["RabbitMQ:Password"] ?? "guest";
        }

        private async Task<IConnection> GetConnectionAsync()
        {

            _logger.LogInformation("Connecting to RabbitMQ at {Host}:{Port} with user {User}", _host, _port, _username);
            
            if (_connection != null && _connection.IsOpen)
                return _connection;

            await _connectionLock.WaitAsync();
            try
            {
                if (_connection != null && _connection.IsOpen)
                    return _connection;

                var factory = new ConnectionFactory
                {
                    HostName = _host,
                    Port = _port,
                    UserName = _username,
                    Password = _password
                };

                _connection = await factory.CreateConnectionAsync();
                _logger.LogInformation("RabbitMQ connection established to {Host}:{Port}", _host, _port);
                return _connection;
            }
            finally
            {
                _connectionLock.Release();
            }
        }

        public async Task PublishAsync<T>(string queueName, T message)
        {
            try
            {
                var connection = await GetConnectionAsync();
                using var channel = await connection.CreateChannelAsync();

                await channel.QueueDeclareAsync(
                    queue: queueName,
                    durable: true,
                    exclusive: false,
                    autoDelete: false);

                var json = JsonConvert.SerializeObject(message);
                var body = Encoding.UTF8.GetBytes(json);

                var properties = new BasicProperties
                {
                    DeliveryMode = DeliveryModes.Persistent
                };

                await channel.BasicPublishAsync(
                    exchange: string.Empty,
                    routingKey: queueName,
                    mandatory: false,
                    basicProperties: properties,
                    body: body);

                _logger.LogInformation("Published message to queue {Queue}", queueName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish message to queue {Queue}", queueName);
                throw;
            }
        }

        public void Dispose()
        {
            _connection?.Dispose();
            _connectionLock.Dispose();
        }
    }
}
