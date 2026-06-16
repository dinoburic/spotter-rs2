using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class WaitlistService : IWaitlistService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly INotificationService _notificationService;
        private readonly ILogger<WaitlistService> _logger;

        public WaitlistService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            INotificationService notificationService,
            ILogger<WaitlistService> logger)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _notificationService = notificationService;
            _logger = logger;
        }

        public async Task<PageResult<WaitlistEntryResponse>> GetAllAsync(WaitlistSearch? search = null)
        {
            var query = _dbContext.WaitlistEntries
                .Include(we => we.User)
                .Include(we => we.Event)
                .Include(we => we.TicketType)
                .AsQueryable();

            if (!_currentUserService.IsAdmin())
            {
                query = query.Where(we => we.UserId == _currentUserService.GetUserId());
            }

            if (search?.EventId.HasValue == true)
            {
                query = query.Where(we => we.EventId == search.EventId.Value);
            }

            if (search?.TicketTypeId.HasValue == true)
            {
                query = query.Where(we => we.TicketTypeId == search.TicketTypeId.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = Math.Min(search?.PageSize ?? 20, 100);

            int? totalCount = null;
            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            var entries = await query
                .OrderBy(we => we.Position)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<WaitlistEntryResponse>
            {
                Items = entries.Select(we => _mapper.Map<WaitlistEntryResponse>(we)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<WaitlistEntryResponse> JoinAsync(WaitlistJoinRequest request)
        {
            var userId = _currentUserService.GetUserId();
            _logger.LogInformation("User {UserId} joining waitlist for event {EventId}, ticket type {TicketTypeId}", userId, request.EventId, request.TicketTypeId);

            if (request.EventId <= 0)
            {
                throw new ClientException("EventId must be greater than 0.");
            }

            if (request.TicketTypeId <= 0)
            {
                throw new ClientException("TicketTypeId must be greater than 0.");
            }

            var eventEntity = await _dbContext.Events.FirstOrDefaultAsync(e => e.Id == request.EventId && !e.IsDeleted);
            if (eventEntity == null)
            {
                _logger.LogWarning("Event {EventId} not found", request.EventId);
                throw new NotFoundException("Event not found.");
            }

            if (eventEntity.Status != EventStatus.Active)
            {
                throw new ClientException("Cannot join waitlist for inactive event.");
            }

            var ticketType = await _dbContext.TicketTypes.FirstOrDefaultAsync(tt => tt.Id == request.TicketTypeId);
            if (ticketType == null)
            {
                throw new NotFoundException("Ticket type not found.");
            }

            if (ticketType.SoldQuantity < ticketType.TotalQuantity)
            {
                throw new ClientException("Tickets are still available for this type. Purchase directly.");
            }

            var alreadyOnWaitlist = await _dbContext.WaitlistEntries
                .AnyAsync(we => we.UserId == userId && we.TicketTypeId == request.TicketTypeId);

            if (alreadyOnWaitlist)
            {
                _logger.LogWarning("User {UserId} already on waitlist for ticket type {TicketTypeId}", userId, request.TicketTypeId);
                throw new ClientException("You are already on the waitlist for this ticket type.");
            }

            var position = await _dbContext.WaitlistEntries
                .CountAsync(we => we.TicketTypeId == request.TicketTypeId) + 1;

            var entry = new WaitlistEntry
            {
                UserId = userId,
                EventId = request.EventId,
                TicketTypeId = request.TicketTypeId,
                Position = position,
                JoinedAt = DateTime.UtcNow,
                Notified = false
            };

            _dbContext.WaitlistEntries.Add(entry);
            await _dbContext.SaveChangesAsync();

            await _notificationService.CreateAsync(
                userId,
                "Added to Waitlist",
                $"You are #{position} on the waitlist for {ticketType.Name} at {eventEntity.Title}. We will notify you when a spot becomes available.",
                NotificationType.WaitlistUpdate,
                entry.Id.ToString()
            );

            var createdEntry = await _dbContext.WaitlistEntries
                .Include(we => we.User)
                .Include(we => we.Event)
                .Include(we => we.TicketType)
                .FirstAsync(we => we.Id == entry.Id);

            return _mapper.Map<WaitlistEntryResponse>(createdEntry);
        }

        public async Task LeaveAsync(int entryId)
        {
            _logger.LogInformation("Leaving waitlist entry {EntryId}", entryId);
            var entry = await _dbContext.WaitlistEntries.FirstOrDefaultAsync(we => we.Id == entryId);

            if (entry == null)
            {
                _logger.LogWarning("Waitlist entry {EntryId} not found", entryId);
                throw new NotFoundException("Waitlist entry not found.");
            }

            if (entry.UserId != _currentUserService.GetUserId() && !_currentUserService.IsAdmin())
            {
                throw new ClientException("Access denied.");
            }

            var removedPosition = entry.Position;
            var ticketTypeId = entry.TicketTypeId;

            _dbContext.WaitlistEntries.Remove(entry);

            var entriesToReorder = await _dbContext.WaitlistEntries
                .Where(we => we.TicketTypeId == ticketTypeId && we.Position > removedPosition)
                .ToListAsync();

            foreach (var e in entriesToReorder)
            {
                e.Position--;
            }

            await _dbContext.SaveChangesAsync();
        }

        public async Task NotifyNextInLineAsync(int ticketTypeId)
        {
            _logger.LogInformation("Notifying next in line for ticket type {TicketTypeId}", ticketTypeId);
            var entry = await _dbContext.WaitlistEntries
                .Include(we => we.TicketType)
                .ThenInclude(tt => tt.Event)
                .Where(we => we.TicketTypeId == ticketTypeId && !we.Notified)
                .OrderBy(we => we.Position)
                .FirstOrDefaultAsync();

            if (entry == null)
            {
                _logger.LogInformation("No unnotified waitlist entries for ticket type {TicketTypeId}", ticketTypeId);
                return;
            }

            entry.Notified = true;
            entry.NotifiedAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Notified user {UserId} for waitlist entry {EntryId}", entry.UserId, entry.Id);
            await _notificationService.CreateAsync(
                entry.UserId,
                "Spot Available!",
                $"A spot opened up for {entry.TicketType.Name} at {entry.TicketType.Event.Title}. Purchase now before it's gone!",
                NotificationType.WaitlistSpotAvailable,
                ticketTypeId.ToString()
            );
        }
    }
}
