namespace Spotter.Services
{
    public interface IRabbitMqPublisher
    {
        Task PublishAsync<T>(string queueName, T message);
    }
}
