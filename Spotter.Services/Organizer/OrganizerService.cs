using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Responses;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class OrganizerService : IOrganizerService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<OrganizerService> _logger;

        public OrganizerService(
            SpotterDbContext dbContext,
            ICurrentUserService currentUserService,
            ILogger<OrganizerService> logger)
        {
            _dbContext = dbContext;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<OrganizerDashboardResponse> GetDashboardAsync()
        {
            var organizerId = _currentUserService.GetUserId();
            _logger.LogInformation("Getting dashboard for organizer {OrganizerId}", organizerId);

            var events = await _dbContext.Events
                .Where(e => e.OrganizerId == organizerId && !e.IsDeleted)
                .ToListAsync();

            var eventIds = events.Select(e => e.Id).ToList();

            var paidOrders = await _dbContext.Orders
                .Include(o => o.OrderItems)
                .Where(o => eventIds.Contains(o.EventId) && o.Status == OrderStatus.Paid)
                .ToListAsync();

            var monthlyRevenue = paidOrders
                .GroupBy(o => new { o.CreatedAt.Year, o.CreatedAt.Month })
                .OrderBy(g => g.Key.Year).ThenBy(g => g.Key.Month)
                .Select(g => new MonthlyRevenueItem
                {
                    Year = g.Key.Year,
                    Month = g.Key.Month,
                    MonthName = new DateTime(g.Key.Year, g.Key.Month, 1).ToString("MMM yyyy"),
                    Revenue = g.Sum(o => o.TotalAmount),
                    TicketsSold = g.Sum(o => o.OrderItems.Sum(oi => oi.Quantity))
                })
                .ToList();

            var topEvents = paidOrders
                .GroupBy(o => o.EventId)
                .Select(g => new TopEventItem
                {
                    EventId = g.Key,
                    Title = events.FirstOrDefault(e => e.Id == g.Key)?.Title ?? string.Empty,
                    TicketsSold = g.Sum(o => o.OrderItems.Sum(oi => oi.Quantity)),
                    Revenue = g.Sum(o => o.TotalAmount)
                })
                .OrderByDescending(e => e.Revenue)
                .Take(5)
                .ToList();

            return new OrganizerDashboardResponse
            {
                TotalRevenue = paidOrders.Sum(o => o.TotalAmount),
                TotalTicketsSold = paidOrders.Sum(o => o.OrderItems.Sum(oi => oi.Quantity)),
                ActiveEventsCount = events.Count(e => e.Status == EventStatus.Active),
                TotalEventsCount = events.Count,
                MonthlyRevenue = monthlyRevenue,
                TopEvents = topEvents
            };
        }
    }
}
