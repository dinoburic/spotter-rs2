using System.Net;
using System.Net.Mail;
using Spotter.Model.Messages;

namespace Spotter.Worker.Services
{
    public class EmailService : IEmailService
    {
        private readonly ILogger<EmailService> _logger;
        private readonly string _smtpHost;
        private readonly int _smtpPort;
        private readonly string _smtpUsername;
        private readonly string _smtpPassword;
        private readonly bool _useSsl;

        public EmailService(ILogger<EmailService> logger)
        {
            _logger = logger;
            _smtpHost = Environment.GetEnvironmentVariable("SMTP_HOST") ?? "smtp.gmail.com";
            _smtpPort = int.Parse(Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587");
            _smtpUsername = Environment.GetEnvironmentVariable("SMTP_USERNAME") ?? string.Empty;
            _smtpPassword = Environment.GetEnvironmentVariable("SMTP_PASSWORD") ?? string.Empty;
            _useSsl = bool.Parse(Environment.GetEnvironmentVariable("SMTP_USE_SSL") ?? "true");
        }

        public async Task SendAsync(EmailMessage message)
        {
            if (string.IsNullOrEmpty(_smtpUsername) || string.IsNullOrEmpty(_smtpPassword))
            {
                _logger.LogWarning("SMTP credentials not configured, skipping email to {To}", message.To);
                return;
            }

            using var client = new SmtpClient(_smtpHost, _smtpPort)
            {
                EnableSsl = _useSsl,
                Credentials = new NetworkCredential(_smtpUsername, _smtpPassword)
            };

            var mail = new MailMessage
            {
                From = new MailAddress(_smtpUsername),
                Subject = message.Subject,
                Body = message.Body,
                IsBodyHtml = message.IsHtml
            };
            mail.To.Add(message.To);

            await client.SendMailAsync(mail);
            _logger.LogInformation("Email sent to {To} with subject {Subject}", message.To, message.Subject);
        }
    }
}
