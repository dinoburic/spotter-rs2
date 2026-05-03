using Spotter.Model.Messages;

namespace Spotter.Worker.Services
{
    public interface IEmailService
    {
        Task SendAsync(EmailMessage message);
    }
}
