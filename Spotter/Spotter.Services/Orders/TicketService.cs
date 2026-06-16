using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Model.Static;
using Spotter.Services.Database;
using Spotter.Services.StateMachines;

namespace Spotter.Services
{
    public class TicketService : ITicketService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly TicketStateMachine _ticketStateMachine;
        private readonly IBadgeService _badgeService;
        private readonly ILogger<TicketService> _logger;

        public TicketService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            TicketStateMachine ticketStateMachine,
            IBadgeService badgeService,
            ILogger<TicketService> logger)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _ticketStateMachine = ticketStateMachine;
            _badgeService = badgeService;
            _logger = logger;
        }

        public async Task<PageResult<TicketResponse>> GetAllAsync(TicketSearch? search = null)
        {
            var query = _dbContext.Tickets
                                    .Include(t => t.User)
                                    .Include(t => t.OrderItem).ThenInclude(oi => oi.TicketType)
                                    .Include(t => t.OrderItem).ThenInclude(oi => oi.Order).ThenInclude(o => o.Event)
                                    .Where(t => t.OrderItem.Order.Status == OrderStatus.Paid)  // DODAJ OVO
                                    .AsQueryable();

            if (!_currentUserService.IsAdmin())
            {
                query = query.Where(t => t.UserId == _currentUserService.GetUserId());
            }

            if (search != null)
            {
                if (search.EventId.HasValue)
                    query = query.Where(t => t.OrderItem.Order.EventId == search.EventId.Value);

                if (search.UserId.HasValue && _currentUserService.IsAdmin())
                    query = query.Where(t => t.UserId == search.UserId.Value);

                if (search.Status.HasValue)
                    query = query.Where(t => t.Status == search.Status.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = Math.Min(search?.PageSize ?? 20, 100);

            int? totalCount = null;
            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            var tickets = await query
                .OrderByDescending(t => t.IssuedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<TicketResponse>
            {
                Items = tickets.Select(t => _mapper.Map<TicketResponse>(t)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<TicketResponse> GetByIdAsync(int id)
        {
            var ticket = await _dbContext.Tickets
                .Include(t => t.User)
                .Include(t => t.OrderItem).ThenInclude(oi => oi.TicketType)
                .Include(t => t.OrderItem).ThenInclude(oi => oi.Order).ThenInclude(o => o.Event)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (ticket == null)
                throw new NotFoundException("Ticket not found.");

            if (!_currentUserService.IsAdmin() && ticket.UserId != _currentUserService.GetUserId())
                throw new ClientException("Access denied.");

            return _mapper.Map<TicketResponse>(ticket);
        }

        public async Task<TicketResponse> UseTicketAsync(string qrCodePayload)
        {
            _logger.LogInformation("Using ticket with QR payload");

            var ticket = await _dbContext.Tickets
                .Include(t => t.User)
                .Include(t => t.OrderItem).ThenInclude(oi => oi.TicketType)
                .Include(t => t.OrderItem).ThenInclude(oi => oi.Order).ThenInclude(o => o.Event)
                .FirstOrDefaultAsync(t => t.QrCodePayload == qrCodePayload);

            if (ticket == null)
            {
                _logger.LogWarning("Ticket not found for QR payload");
                throw new NotFoundException("Ticket not found.");
            }

            var currentUserId = _currentUserService.GetUserId();
            var isAdmin = _currentUserService.IsAdmin();
            var isOrganizer = _currentUserService.IsInRole(Roles.Organizer);

            if (!isAdmin && !(isOrganizer && ticket.OrderItem.Order.Event.OrganizerId == currentUserId))
                throw new ClientException("Only admins or event organizers can validate tickets.");

            if (ticket.OrderItem.Order.Event.StartsAt > DateTime.UtcNow.AddHours(2))
                throw new ClientException("Event has not started yet.");

            _ticketStateMachine.Transition(ticket, TicketStatus.Used);
            ticket.UsedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();

            await _badgeService.EvaluateAndAwardAsync(ticket.UserId);

            _logger.LogInformation("Ticket {TicketId} used successfully", ticket.Id);
            return _mapper.Map<TicketResponse>(ticket);
        }
    }
}
