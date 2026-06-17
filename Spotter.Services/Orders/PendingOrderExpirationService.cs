using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class PendingOrderExpirationService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<PendingOrderExpirationService> _logger;
        private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);
        private static readonly TimeSpan PendingTimeout = TimeSpan.FromMinutes(30);

        public PendingOrderExpirationService(IServiceProvider serviceProvider, ILogger<PendingOrderExpirationService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("PendingOrderExpirationService started");

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(Interval, stoppingToken);

                try
                {
                    using var scope = _serviceProvider.CreateScope();
                    var dbContext = scope.ServiceProvider.GetRequiredService<SpotterDbContext>();
                    var waitlistService = scope.ServiceProvider.GetRequiredService<IWaitlistService>();

                    var cutoff = DateTime.UtcNow.Subtract(PendingTimeout);
                    var expiredOrders = await dbContext.Orders
                        .Include(o => o.OrderItems)
                        .Where(o => o.Status == OrderStatus.Pending && o.CreatedAt < cutoff)
                        .ToListAsync(stoppingToken);

                    if (expiredOrders.Count == 0)
                        continue;

                    var ticketTypeIdsToNotify = new List<int>();

                    foreach (var order in expiredOrders)
                    {
                        order.Status = OrderStatus.Cancelled;

                        foreach (var item in order.OrderItems)
                        {
                            var ticketType = await dbContext.TicketTypes
                                .FirstOrDefaultAsync(tt => tt.Id == item.TicketTypeId, stoppingToken);
                            if (ticketType != null)
                            {
                                ticketType.SoldQuantity = Math.Max(0, ticketType.SoldQuantity - item.Quantity);
                                ticketTypeIdsToNotify.Add(item.TicketTypeId);
                            }
                        }

                        if (order.SpotterPointsRedeemed > 0)
                        {
                            dbContext.SpotterPoints.Add(new SpotterPoints
                            {
                                UserId = order.UserId,
                                Delta = order.SpotterPointsRedeemed,
                                Source = PointSource.Redemption,
                                Description = "Points restored from expired order",
                                CreatedAt = DateTime.UtcNow
                            });
                            _logger.LogInformation("Restored {Points} points for expired order {OrderId}", order.SpotterPointsRedeemed, order.Id);
                        }

                        _logger.LogInformation("Expired pending order {OrderId} cancelled", order.Id);
                    }

                    await dbContext.SaveChangesAsync(stoppingToken);

                    foreach (var ticketTypeId in ticketTypeIdsToNotify.Distinct())
                    {
                        await waitlistService.NotifyNextInLineAsync(ticketTypeId);
                    }

                    _logger.LogInformation("Cancelled {Count} expired pending orders", expiredOrders.Count);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error during pending order expiration");
                }
            }

            _logger.LogInformation("PendingOrderExpirationService stopped");
        }
    }
}
