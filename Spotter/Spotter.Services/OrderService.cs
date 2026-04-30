using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;
using System.Text;

namespace Spotter.Services
{
    public class OrderService : IOrderService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly IValidator<OrderInsertRequest> _validator;
        private readonly INotificationService _notificationService;

        public OrderService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            IValidator<OrderInsertRequest> validator,
            INotificationService notificationService)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _validator = validator;
            _notificationService = notificationService;
        }

        public async Task<PageResult<OrderResponse>> GetAllAsync(OrderSearch? search = null)
        {
            var query = _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Event)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.TicketType)
                .AsQueryable();

            if (!_currentUserService.IsAdmin())
            {
                query = query.Where(o => o.UserId == _currentUserService.GetUserId());
            }

            if (search != null)
            {
                if (search.EventId.HasValue)
                    query = query.Where(o => o.EventId == search.EventId.Value);

                if (search.UserId.HasValue && _currentUserService.IsAdmin())
                    query = query.Where(o => o.UserId == search.UserId.Value);

                if (search.Status.HasValue)
                    query = query.Where(o => o.Status == search.Status.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = Math.Min(search?.PageSize ?? 20, 100);

            int? totalCount = null;
            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            var orders = await query
                .OrderByDescending(o => o.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<OrderResponse>
            {
                Items = orders.Select(o => _mapper.Map<OrderResponse>(o)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<OrderResponse> GetByIdAsync(int id)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Event)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.TicketType)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
                throw new NotFoundException("Order not found.");

            if (!_currentUserService.IsAdmin() && order.UserId != _currentUserService.GetUserId())
                throw new ClientException("Access denied.");

            return _mapper.Map<OrderResponse>(order);
        }

        public async Task<OrderResponse> CreateOrderAsync(OrderInsertRequest request)
        {
            await _validator.ValidateAndThrowAsync(request);

            var eventEntity = await _dbContext.Events
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == request.EventId && !e.IsDeleted);

            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            if (eventEntity.Status != EventStatus.Active)
                throw new ClientException("Only active events accept orders.");

            var ticketTypesDict = new Dictionary<int, TicketType>();
            foreach (var item in request.Items)
            {
                var ticketType = eventEntity.TicketTypes.FirstOrDefault(tt => tt.Id == item.TicketTypeId);
                if (ticketType == null)
                    throw new NotFoundException($"TicketType {item.TicketTypeId} not found for this event.");

                var available = ticketType.TotalQuantity - ticketType.SoldQuantity;
                if (item.Quantity > available)
                    throw new ClientException($"Not enough tickets available for {ticketType.Name}. Available: {available}.");

                ticketTypesDict[item.TicketTypeId] = ticketType;
            }

            await using var transaction = await _dbContext.Database.BeginTransactionAsync();

            var userId = _currentUserService.GetUserId();
            var totalAmount = request.Items.Sum(i => i.Quantity * ticketTypesDict[i.TicketTypeId].Price);

            var order = new Order
            {
                UserId = userId,
                EventId = request.EventId,
                Status = OrderStatus.Pending,
                CreatedAt = DateTime.UtcNow,
                TotalAmount = totalAmount,
                SpotterPointsRedeemed = 0,
                DiscountApplied = 0
            };

            _dbContext.Orders.Add(order);
            await _dbContext.SaveChangesAsync();

            foreach (var item in request.Items)
            {
                var ticketType = ticketTypesDict[item.TicketTypeId];

                var orderItem = new OrderItem
                {
                    OrderId = order.Id,
                    TicketTypeId = item.TicketTypeId,
                    Quantity = item.Quantity,
                    UnitPrice = ticketType.Price
                };

                _dbContext.OrderItems.Add(orderItem);
                await _dbContext.SaveChangesAsync();

                for (int i = 0; i < item.Quantity; i++)
                {
                    var ticket = new Ticket
                    {
                        UserId = userId,
                        OrderItemId = orderItem.Id,
                        QrCodePayload = GenerateQrPayload(order.Id, orderItem.Id, item.TicketTypeId),
                        Status = TicketStatus.Active,
                        IssuedAt = DateTime.UtcNow
                    };
                    _dbContext.Tickets.Add(ticket);
                }

                ticketType.SoldQuantity += item.Quantity;
            }

            await _dbContext.SaveChangesAsync();
            await transaction.CommitAsync();

            var createdOrder = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Event)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.TicketType)
                .FirstAsync(o => o.Id == order.Id);

            var totalTickets = request.Items.Sum(i => i.Quantity);
            await _notificationService.CreateAsync(
                userId: userId,
                title: "Order Confirmed",
                body: $"Your order for {eventEntity.Title} has been confirmed. {totalTickets} ticket(s) issued.",
                type: NotificationType.General,
                referenceId: order.Id.ToString()
            );

            return _mapper.Map<OrderResponse>(createdOrder);
        }

        public async Task<OrderResponse> MarkAsPaidAsync(int id)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Event)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.TicketType)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
                throw new NotFoundException("Order not found.");

            if (order.Status != OrderStatus.Pending)
                throw new ClientException("Only pending orders can be marked as paid.");

            order.Status = OrderStatus.Paid;
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<OrderResponse>(order);
        }

        public async Task<OrderResponse> RefundAsync(int id)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Event)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.TicketType)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Tickets)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
                throw new NotFoundException("Order not found.");

            if (order.Status != OrderStatus.Paid)
                throw new ClientException("Only paid orders can be refunded.");

            await using var transaction = await _dbContext.Database.BeginTransactionAsync();

            order.Status = OrderStatus.Refunded;

            foreach (var orderItem in order.OrderItems)
            {
                foreach (var ticket in orderItem.Tickets.Where(t => t.Status == TicketStatus.Active))
                {
                    ticket.Status = TicketStatus.Cancelled;
                }

                var ticketType = await _dbContext.TicketTypes.FindAsync(orderItem.TicketTypeId);
                if (ticketType != null)
                {
                    ticketType.SoldQuantity -= orderItem.Quantity;
                }
            }

            await _dbContext.SaveChangesAsync();
            await transaction.CommitAsync();

            return _mapper.Map<OrderResponse>(order);
        }

        private static string GenerateQrPayload(int orderId, int orderItemId, int ticketTypeId)
        {
            var raw = $"SPOTTER-{orderId}-{orderItemId}-{ticketTypeId}-{Guid.NewGuid():N}";
            return Convert.ToBase64String(Encoding.UTF8.GetBytes(raw));
        }
    }
}
