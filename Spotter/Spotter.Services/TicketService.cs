using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
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

        public TicketService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            TicketStateMachine ticketStateMachine,
            IBadgeService badgeService)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _ticketStateMachine = ticketStateMachine;
            _badgeService = badgeService;
        }

        public async Task<PageResult<TicketResponse>> GetAllAsync(TicketSearch? search = null)
        {
            var query = _dbContext.Tickets
                .Include(t => t.User)
                .Include(t => t.OrderItem).ThenInclude(oi => oi.TicketType)
                .Include(t => t.OrderItem).ThenInclude(oi => oi.Order).ThenInclude(o => o.Event)
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
            if (!_currentUserService.IsAdmin())
                throw new ClientException("Only organizers or admins can scan tickets.");

            var ticket = await _dbContext.Tickets
                .Include(t => t.User)
                .Include(t => t.OrderItem).ThenInclude(oi => oi.TicketType)
                .Include(t => t.OrderItem).ThenInclude(oi => oi.Order).ThenInclude(o => o.Event)
                .FirstOrDefaultAsync(t => t.QrCodePayload == qrCodePayload);

            if (ticket == null)
                throw new NotFoundException("Ticket not found.");

            if (ticket.OrderItem.Order.Event.StartsAt > DateTime.UtcNow.AddHours(2))
                throw new ClientException("Event has not started yet.");

            _ticketStateMachine.Transition(ticket, TicketStatus.Used);

            await _dbContext.SaveChangesAsync();

            await _badgeService.EvaluateAndAwardAsync(ticket.UserId);

            return _mapper.Map<TicketResponse>(ticket);
        }
    }
}
