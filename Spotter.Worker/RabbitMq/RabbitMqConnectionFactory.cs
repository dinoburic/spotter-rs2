using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace Spotter.Worker.RabbitMq
{
    public class RabbitMqConnectionFactory : IRabbitMqConnectionFactory
    {
        private readonly string _host;
        private readonly int _port;
        private readonly string _username;
        private readonly string _password;

        public RabbitMqConnectionFactory(IConfiguration configuration)
        {
            _host = configuration["RabbitMQ:Host"] ?? Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
            _port = int.Parse(configuration["RabbitMQ:Port"] ?? Environment.GetEnvironmentVariable("RABBITMQ_PORT") ?? "5672");
            _username = configuration["RabbitMQ:Username"] ?? Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
            _password = configuration["RabbitMQ:Password"] ?? Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
        }

        public async Task<IConnection> CreateConnectionAsync()
        {
            var factory = new ConnectionFactory
            {
                HostName = _host,
                Port = _port,
                UserName = _username,
                Password = _password
            };
            return await factory.CreateConnectionAsync();
        }
    }
}
