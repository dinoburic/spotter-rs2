using RabbitMQ.Client;

namespace Spotter.Worker.RabbitMq
{
    public class RabbitMqConnectionFactory : IRabbitMqConnectionFactory
    {
        private readonly string _host;
        private readonly int _port;
        private readonly string _username;
        private readonly string _password;

        public RabbitMqConnectionFactory()
        {
            _host = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
            _port = int.Parse(Environment.GetEnvironmentVariable("RABBITMQ_PORT") ?? "5672");
            _username = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
            _password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
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
