using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Responses;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class ReportService : IReportService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly ILogger<ReportService> _logger;

        public ReportService(SpotterDbContext dbContext, ILogger<ReportService> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<FinancialReportResponse> GetFinancialReportAsync(DateTime? from, DateTime? to, int? categoryId)
        {
            _logger.LogInformation("Generating financial report from {From} to {To}, category {CategoryId}", from, to, categoryId);

            var query = _dbContext.Orders
                .Include(o => o.Event).ThenInclude(e => e!.Category)
                .Include(o => o.OrderItems)
                .Where(o => o.Status == OrderStatus.Paid);

            if (from.HasValue)
                query = query.Where(o => o.CreatedAt >= from.Value);
            if (to.HasValue)
                query = query.Where(o => o.CreatedAt <= to.Value);
            if (categoryId.HasValue)
                query = query.Where(o => o.Event != null && o.Event.CategoryId == categoryId.Value);

            var orders = await query.ToListAsync();

            var response = new FinancialReportResponse
            {
                TotalRevenue = orders.Sum(o => o.TotalAmount),
                TotalOrders = orders.Count,
                TotalTicketsSold = orders.Sum(o => o.OrderItems.Sum(oi => oi.Quantity)),
                Orders = orders.Select(o => new FinancialOrderItem
                {
                    OrderId = o.Id,
                    EventTitle = o.Event?.Title ?? string.Empty,
                    CategoryName = o.Event?.Category?.Name ?? string.Empty,
                    TotalAmount = o.TotalAmount,
                    CreatedAt = o.CreatedAt,
                    TicketCount = o.OrderItems.Sum(oi => oi.Quantity)
                }).ToList()
            };

            _logger.LogInformation("Financial report generated: {OrderCount} orders, {Revenue} BAM revenue", response.TotalOrders, response.TotalRevenue);
            return response;
        }

        public async Task<GuestListResponse> GetGuestListAsync(DateTime? from, DateTime? to, int? categoryId, int? eventId)
        {
            _logger.LogInformation("Generating guest list from {From} to {To}, category {CategoryId}, event {EventId}", from, to, categoryId, eventId);

            var query = _dbContext.Tickets
                .Include(t => t.User)
                .Include(t => t.OrderItem)
                    .ThenInclude(oi => oi.Order)
                    .ThenInclude(o => o!.Event)
                    .ThenInclude(e => e!.Category)
                .Include(t => t.OrderItem)
                    .ThenInclude(oi => oi.TicketType)
                .Where(t => t.OrderItem.Order != null && t.OrderItem.Order.Status == OrderStatus.Paid);

            if (from.HasValue)
                query = query.Where(t => t.OrderItem.Order!.CreatedAt >= from.Value);
            if (to.HasValue)
                query = query.Where(t => t.OrderItem.Order!.CreatedAt <= to.Value);
            if (categoryId.HasValue)
                query = query.Where(t => t.OrderItem.Order!.Event != null && t.OrderItem.Order.Event.CategoryId == categoryId.Value);
            if (eventId.HasValue)
                query = query.Where(t => t.OrderItem.Order!.EventId == eventId.Value);

            var tickets = await query.ToListAsync();

            var response = new GuestListResponse
            {
                TotalGuests = tickets.Count,
                Guests = tickets.Select(t => new GuestItem
                {
                    TicketId = t.Id,
                    UserFullName = t.User != null ? $"{t.User.FirstName} {t.User.LastName}" : string.Empty,
                    UserEmail = t.User?.Email ?? string.Empty,
                    EventTitle = t.OrderItem.Order?.Event?.Title ?? string.Empty,
                    CategoryName = t.OrderItem.Order?.Event?.Category?.Name ?? string.Empty,
                    TicketTypeName = t.OrderItem.TicketType?.Name ?? string.Empty,
                    IssuedAt = t.IssuedAt,
                    Status = t.Status.ToString()
                }).ToList()
            };

            _logger.LogInformation("Guest list generated: {GuestCount} guests", response.TotalGuests);
            return response;
        }
    }
}
