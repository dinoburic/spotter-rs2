using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;
using Spotter.Services.StateMachines;
using System.Text;
using System.Data;
using Spotter.Model.Messages;

namespace Spotter.Services
{
    public class OrderService : IOrderService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly IValidator<OrderInsertRequest> _validator;
        private readonly INotificationService _notificationService;
        private readonly OrderStateMachine _orderStateMachine;
        private readonly TicketStateMachine _ticketStateMachine;
        private readonly ISpotterPointsService _spotterPointsService;
        private readonly IBadgeService _badgeService;
        private readonly IWaitlistService _waitlistService;
        private readonly IStripeService _stripeService;
        private readonly IRabbitMqPublisher _rabbitMqPublisher;
        private readonly ILogger<OrderService> _logger;

        public OrderService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            IValidator<OrderInsertRequest> validator,
            INotificationService notificationService,
            OrderStateMachine orderStateMachine,
            TicketStateMachine ticketStateMachine,
            ISpotterPointsService spotterPointsService,
            IBadgeService badgeService,
            IWaitlistService waitlistService,
            IStripeService stripeService,
            IRabbitMqPublisher rabbitMqPublisher,
            ILogger<OrderService> logger)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _rabbitMqPublisher = rabbitMqPublisher;
            _currentUserService = currentUserService;
            _validator = validator;
            _notificationService = notificationService;
            _orderStateMachine = orderStateMachine;
            _ticketStateMachine = ticketStateMachine;
            _spotterPointsService = spotterPointsService;
            _badgeService = badgeService;
            _waitlistService = waitlistService;
            _stripeService = stripeService;
            _logger = logger;
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
            var userId = _currentUserService.GetUserId();
            _logger.LogInformation("Creating order for user {UserId} event {EventId}", userId, request.EventId);

            try
            {
                await _validator.ValidateAndThrowAsync(request);

                var eventEntity = await _dbContext.Events
                    .Include(e => e.TicketTypes)
                    .FirstOrDefaultAsync(e => e.Id == request.EventId && !e.IsDeleted);

                if (eventEntity == null)
                {
                    _logger.LogWarning("Event {EventId} not found", request.EventId);
                    throw new NotFoundException("Event not found.");
                }

                if (eventEntity.Status != EventStatus.Active)
                    throw new ClientException("Only active events accept orders.");

                var ticketTypesDict = new Dictionary<int, TicketType>();
                foreach (var item in request.Items)
                {
                    var ticketType = eventEntity.TicketTypes.FirstOrDefault(tt => tt.Id == item.TicketTypeId);
                    if (ticketType == null)
                        throw new NotFoundException($"TicketType {item.TicketTypeId} not found for this event.");

                    ticketTypesDict[item.TicketTypeId] = ticketType;
                }

                await using var transaction = await _dbContext.Database.BeginTransactionAsync(IsolationLevel.Serializable);

                try
                {
                    foreach (var item in request.Items)
                    {
                        var rowsAffected = await _dbContext.Database.ExecuteSqlRawAsync(
                            @"UPDATE TicketTypes
                              SET SoldQuantity = SoldQuantity + {0}
                              WHERE Id = {1}
                              AND (TotalQuantity - SoldQuantity) >= {0}",
                            item.Quantity,
                            item.TicketTypeId);

                        if (rowsAffected == 0)
                        {
                            await transaction.RollbackAsync();
                            var ticketType = ticketTypesDict[item.TicketTypeId];
                            throw new ClientException($"Not enough tickets available for {ticketType.Name}. Another user may have just purchased the last tickets. Please try again.");
                        }
                    }

                    var subtotal = request.Items.Sum(i => i.Quantity * ticketTypesDict[i.TicketTypeId].Price);
                    var spotterPointsRedeemed = 0;
                    var discountApplied = 0m;

                    if (request.SpotterPointsToRedeem > 0)
                    {
                        var userBalance = await _dbContext.SpotterPoints
                            .Where(sp => sp.UserId == userId)
                            .SumAsync(sp => sp.Delta);

                        var pointsToRedeem = Math.Min(request.SpotterPointsToRedeem, userBalance);
                        discountApplied = Math.Min(pointsToRedeem * 0.1m, subtotal);
                        spotterPointsRedeemed = (int)(discountApplied / 0.1m);

                        if (spotterPointsRedeemed > 0)
                        {
                            _dbContext.SpotterPoints.Add(new SpotterPoints
                            {
                                UserId = userId,
                                Delta = -spotterPointsRedeemed,
                                Source = PointSource.Redemption,
                                Description = "Order discount",
                                CreatedAt = DateTime.UtcNow
                            });
                            _logger.LogInformation("User {UserId} redeemed {Points} points for {Discount} BAM discount", userId, spotterPointsRedeemed, discountApplied);
                        }
                    }

                    var totalAmount = subtotal - discountApplied;
                    var isZeroAmount = totalAmount == 0;

                    var order = new Order
                    {
                        UserId = userId,
                        EventId = request.EventId,
                        Status = isZeroAmount ? OrderStatus.Paid : OrderStatus.Pending,
                        CreatedAt = DateTime.UtcNow,
                        TotalAmount = totalAmount,
                        SpotterPointsRedeemed = spotterPointsRedeemed,
                        DiscountApplied = discountApplied
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
                    }

                    await _dbContext.SaveChangesAsync();

                    if (isZeroAmount)
                    {
                        var ticketCount = 0;
                        var orderItems = await _dbContext.OrderItems
                            .Where(oi => oi.OrderId == order.Id)
                            .ToListAsync();

                        foreach (var orderItem in orderItems)
                        {
                            for (int i = 0; i < orderItem.Quantity; i++)
                            {
                                var ticket = new Ticket
                                {
                                    UserId = order.UserId,
                                    OrderItemId = orderItem.Id,
                                    QrCodePayload = GenerateQrPayload(order.Id, orderItem.Id, orderItem.TicketTypeId),
                                    Status = TicketStatus.Active,
                                    IssuedAt = DateTime.UtcNow
                                };
                                _dbContext.Tickets.Add(ticket);
                                ticketCount++;
                            }
                        }
                        await _dbContext.SaveChangesAsync();
                        _logger.LogInformation("Zero-amount order {OrderId}: {Count} tickets issued immediately", order.Id, ticketCount);
                    }

                    await transaction.CommitAsync();

                    var createdOrder = await _dbContext.Orders
                        .Include(o => o.User)
                        .Include(o => o.Event)
                        .Include(o => o.OrderItems).ThenInclude(oi => oi.TicketType)
                        .FirstAsync(o => o.Id == order.Id);

                    if (isZeroAmount)
                    {
                        await _notificationService.CreateAsync(
                            userId: userId,
                            title: "Order Complete",
                            body: $"Your tickets for {eventEntity.Title} have been issued!",
                            type: NotificationType.OrderPaid,
                            referenceId: order.Id.ToString()
                        );
                    }
                    else
                    {
                        await _notificationService.CreateAsync(
                            userId: userId,
                            title: "Order Created",
                            body: $"Your order for {eventEntity.Title} has been created. Complete payment to receive your tickets.",
                            type: NotificationType.OrderCreated,
                            referenceId: order.Id.ToString()
                        );
                    }

                    _logger.LogInformation("Order {OrderId} created successfully for user {UserId}", order.Id, userId);
                    return _mapper.Map<OrderResponse>(createdOrder);
                }
                catch (ClientException)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    _logger.LogError(ex, "Order creation failed for user {UserId}", userId);
                    throw;
                }
            }
            catch (Exception ex) when (ex is not ClientException and not NotFoundException)
            {
                _logger.LogError(ex, "Failed to create order for user {UserId}", userId);
                throw;
            }
        }

        public async Task<OrderResponse> MarkAsPaidAsync(int id)
        {
            _logger.LogInformation("Marking order {OrderId} as paid", id);
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Event)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.TicketType)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
            {
                _logger.LogWarning("Order {OrderId} not found", id);
                throw new NotFoundException("Order not found.");
            }

            if (order.Status == OrderStatus.Paid)
            {
                _logger.LogInformation("Order {OrderId} already paid, skipping", id);
                return _mapper.Map<OrderResponse>(order);
            }

            await using var transaction = await _dbContext.Database.BeginTransactionAsync();

            try
            {
                _orderStateMachine.Transition(order, OrderStatus.Paid);

                var ticketCount = 0;
                foreach (var orderItem in order.OrderItems)
                {
                    for (int i = 0; i < orderItem.Quantity; i++)
                    {
                        var ticket = new Ticket
                        {
                            UserId = order.UserId,
                            OrderItemId = orderItem.Id,
                            QrCodePayload = GenerateQrPayload(order.Id, orderItem.Id, orderItem.TicketTypeId),
                            Status = TicketStatus.Active,
                            IssuedAt = DateTime.UtcNow
                        };
                        _dbContext.Tickets.Add(ticket);
                        ticketCount++;
                    }
                }

                await _dbContext.SaveChangesAsync();

                var pointsToEarn = Math.Max(1, (int)Math.Floor(order.TotalAmount / 10));
                await _spotterPointsService.EarnAsync(
                    order.UserId,
                    pointsToEarn,
                    PointSource.Purchase,
                    order.Id.ToString(),
                    $"Purchase: {order.Event.Title}"
                );

                await _badgeService.EvaluateAndAwardAsync(order.UserId);

                await transaction.CommitAsync();

                _logger.LogInformation("Order {OrderId} paid, {Count} tickets issued", order.Id, ticketCount);

                await _notificationService.CreateAsync(
                    userId: order.UserId,
                    title: "Payment Successful",
                    body: $"Your payment was successful! {ticketCount} ticket(s) for {order.Event.Title} have been issued.",
                    type: NotificationType.OrderPaid,
                    referenceId: order.Id.ToString()
                );

                await _rabbitMqPublisher.PublishAsync(QueueNames.Email, new EmailMessage
                {
                    To = order.User?.Email ?? string.Empty,
                    Subject = $"Your tickets for {order.Event?.Title}",
                    Body = $"Your payment was successful! {ticketCount} ticket(s) issued."
                });

                return _mapper.Map<OrderResponse>(order);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Failed to mark order {OrderId} as paid", id);
                throw;
            }
        }

        public async Task<OrderResponse> RefundAsync(int id)
        {
            _logger.LogInformation("Refunding order {OrderId}", id);
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Event)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.TicketType)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Tickets)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
            {
                _logger.LogWarning("Order {OrderId} not found", id);
                throw new NotFoundException("Order not found.");
            }

            if (order.Status != OrderStatus.Paid)
                throw new ClientException("Only paid orders can be refunded.");

            order.RefundStatus = "Processing";
            await _dbContext.SaveChangesAsync();

            try
            {
                if (!string.IsNullOrEmpty(order.StripePaymentIntentId))
                {
                    await _stripeService.RefundPaymentAsync(order.StripePaymentIntentId);
                    _logger.LogInformation("Stripe refund initiated for order {OrderId}", id);
                }

                await using var transaction = await _dbContext.Database.BeginTransactionAsync();

                _orderStateMachine.Transition(order, OrderStatus.Refunded);
                order.RefundStatus = "Completed";

                var ticketTypeIdsToNotify = new List<int>();

                foreach (var orderItem in order.OrderItems)
                {
                    foreach (var ticket in orderItem.Tickets.Where(t => t.Status == TicketStatus.Active))
                    {
                        _ticketStateMachine.Transition(ticket, TicketStatus.Cancelled);
                    }

                    var ticketType = await _dbContext.TicketTypes.FindAsync(orderItem.TicketTypeId);
                    if (ticketType != null)
                    {
                        ticketType.SoldQuantity = Math.Max(0, ticketType.SoldQuantity - orderItem.Quantity);
                        ticketTypeIdsToNotify.Add(orderItem.TicketTypeId);
                    }
                }

                if (order.SpotterPointsRedeemed > 0)
                {
                    await _spotterPointsService.EarnAsync(
                        order.UserId,
                        order.SpotterPointsRedeemed,
                        PointSource.Redemption,
                        order.Id.ToString(),
                        "Points restored from refunded order"
                    );
                    _logger.LogInformation("Restored {Points} points for refunded order {OrderId}", order.SpotterPointsRedeemed, order.Id);
                }

                await _dbContext.SaveChangesAsync();
                await transaction.CommitAsync();

                foreach (var ticketTypeId in ticketTypeIdsToNotify.Distinct())
                {
                    await _waitlistService.NotifyNextInLineAsync(ticketTypeId);
                }

                _logger.LogInformation("Order {OrderId} refunded successfully", id);
                return _mapper.Map<OrderResponse>(order);
            }
            catch (Exception ex)
            {
                order.RefundStatus = "Failed";
                await _dbContext.SaveChangesAsync();
                _logger.LogError(ex, "Failed to refund order {OrderId}", id);
                throw;
            }
        }

        public async Task CancelAsync(int id)
        {
            _logger.LogInformation("Cancelling order {OrderId}", id);
            var order = await _dbContext.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
            {
                _logger.LogWarning("Order {OrderId} not found", id);
                throw new NotFoundException($"Order {id} not found.");
            }

            var currentUserId = _currentUserService.GetUserId();
            var isAdmin = _currentUserService.IsAdmin();

            if (!isAdmin && order.UserId != currentUserId)
                throw new ClientException("You can only cancel your own orders.");

            if (order.Status == OrderStatus.Cancelled)
            {
                _logger.LogInformation("Order {OrderId} already cancelled, skipping", id);
                return;
            }

            if (order.Status == OrderStatus.Pending)
            {
                foreach (var item in order.OrderItems)
                {
                    var ticketType = await _dbContext.TicketTypes.FindAsync(item.TicketTypeId);
                    if (ticketType != null)
                    {
                        ticketType.SoldQuantity = Math.Max(0, ticketType.SoldQuantity - item.Quantity);
                    }
                }

                if (order.SpotterPointsRedeemed > 0)
                {
                    await _spotterPointsService.EarnAsync(
                        order.UserId,
                        order.SpotterPointsRedeemed,
                        PointSource.Redemption,
                        order.Id.ToString(),
                        "Points restored from cancelled order"
                    );
                    _logger.LogInformation("Restored {Points} points for cancelled order {OrderId}", order.SpotterPointsRedeemed, order.Id);
                }
            }

            _orderStateMachine.Transition(order, OrderStatus.Cancelled);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Order {OrderId} cancelled successfully", id);
        }

        public async Task CancelBySystemAsync(int orderId)
        {
            _logger.LogInformation("Cancelling order {OrderId} by system", orderId);

            var order = await _dbContext.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.Id == orderId);

            if (order == null)
            {
                _logger.LogWarning("Order {OrderId} not found for system cancellation", orderId);
                return;
            }

            if (order.Status == OrderStatus.Cancelled)
            {
                _logger.LogInformation("Order {OrderId} already cancelled", orderId);
                return;
            }

            if (order.Status == OrderStatus.Pending)
            {
                foreach (var item in order.OrderItems)
                {
                    var ticketType = await _dbContext.TicketTypes.FindAsync(item.TicketTypeId);
                    if (ticketType != null)
                    {
                        ticketType.SoldQuantity = Math.Max(0, ticketType.SoldQuantity - item.Quantity);
                    }
                }

                if (order.SpotterPointsRedeemed > 0)
                {
                    await _spotterPointsService.EarnAsync(
                        order.UserId,
                        order.SpotterPointsRedeemed,
                        PointSource.Redemption,
                        order.Id.ToString(),
                        "Points restored from cancelled order"
                    );
                    _logger.LogInformation("Restored {Points} points for system-cancelled order {OrderId}", order.SpotterPointsRedeemed, order.Id);
                }
            }

            _orderStateMachine.Transition(order, OrderStatus.Cancelled);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Order {OrderId} cancelled by system (webhook)", orderId);
        }

        private static string GenerateQrPayload(int orderId, int orderItemId, int ticketTypeId)
        {
            var raw = $"SPOTTER-{orderId}-{orderItemId}-{ticketTypeId}-{Guid.NewGuid():N}";
            return Convert.ToBase64String(Encoding.UTF8.GetBytes(raw));
        }
    }
}
