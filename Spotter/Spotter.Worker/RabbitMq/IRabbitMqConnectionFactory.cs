using RabbitMQ.Client;

namespace Spotter.Worker.RabbitMq
{
    public interface IRabbitMqConnectionFactory
    {
        Task<IConnection> CreateConnectionAsync();
    }
}
