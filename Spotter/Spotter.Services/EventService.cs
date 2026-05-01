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

namespace Spotter.Services
{
    public class EventService : BaseCRUDService<Event, EventResponse, EventSearch, EventInsertRequest, EventUpdateRequest>, IEventService
    {
        private readonly ICurrentUserService _currentUserService;
        private readonly EventStateMachine _eventStateMachine;
        private readonly ILogger<EventService> _logger;

        public EventService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<EventInsertRequest> insertValidator,
            IValidator<EventUpdateRequest> updateValidator,
            ICurrentUserService currentUserService,
            EventStateMachine eventStateMachine,
            ILogger<EventService> logger)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _currentUserService = currentUserService;
            _eventStateMachine = eventStateMachine;
            _logger = logger;
        }

        protected override Task<IQueryable<Event>> IncludeRelatedEntitiesAsync(EventSearch? search, IQueryable<Event> query)
        {
            query = query
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.Organizer)
                .Include(e => e.TicketTypes);
            return Task.FromResult(query);
        }

        protected override IQueryable<Event> ApplyFilters(IQueryable<Event> query, EventSearch? search)
        {
            if (search == null)
                return query.Where(e => !e.IsDeleted);

            if (!string.IsNullOrWhiteSpace(search.Title))
                query = query.Where(e => e.Title.Contains(search.Title));

            if (search.CategoryId.HasValue)
                query = query.Where(e => e.CategoryId == search.CategoryId.Value);

            if (search.CityId.HasValue)
                query = query.Where(e => e.Venue.City.Id == search.CityId.Value);

            if (search.VenueId.HasValue)
                query = query.Where(e => e.VenueId == search.VenueId.Value);

            if (search.OrganizerId.HasValue)
                query = query.Where(e => e.OrganizerId == search.OrganizerId.Value);

            if (search.Status.HasValue)
                query = query.Where(e => e.Status == search.Status.Value);

            if (search.StartsAfter.HasValue)
                query = query.Where(e => e.StartsAt >= search.StartsAfter.Value);

            if (search.StartsBefore.HasValue)
                query = query.Where(e => e.StartsAt <= search.StartsBefore.Value);

            if (!search.IncludeDeleted)
                query = query.Where(e => !e.IsDeleted);

            return query;
        }

        public override async Task<EventResponse> InsertAsync(EventInsertRequest request)
        {
            var organizerId = _currentUserService.GetUserId();
            _logger.LogInformation("Creating event {Title} for organizer {OrganizerId}", request.Title, organizerId);
            await _insertValidator.ValidateAndThrowAsync(request);

            var categoryExists = await _dbContext.Categories.AnyAsync(c => c.Id == request.CategoryId);
            if (!categoryExists)
            {
                _logger.LogWarning("Category {CategoryId} not found", request.CategoryId);
                throw new NotFoundException("Category not found.");
            }

            var venueExists = await _dbContext.Venues.AnyAsync(v => v.Id == request.VenueId);
            if (!venueExists)
            {
                _logger.LogWarning("Venue {VenueId} not found", request.VenueId);
                throw new NotFoundException("Venue not found.");
            }

            var entity = _mapper.Map<Event>(request);
            entity.OrganizerId = organizerId;
            entity.Status = EventStatus.Draft;
            entity.CreatedAt = DateTime.UtcNow;
            entity.GeocodingPending = false;
            entity.IsDeleted = false;

            _dbContext.Events.Add(entity);
            await _dbContext.SaveChangesAsync();

            var createdEvent = await _dbContext.Events
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.Organizer)
                .Include(e => e.TicketTypes)
                .FirstAsync(e => e.Id == entity.Id);

            _logger.LogInformation("Event {EventId} created successfully", entity.Id);
            return _mapper.Map<EventResponse>(createdEvent);
        }

        public override async Task<EventResponse> UpdateAsync(int id, EventUpdateRequest request)
        {
            _logger.LogInformation("Updating event {EventId}", id);
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.Events
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.Organizer)
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (entity == null)
            {
                _logger.LogWarning("Event {EventId} not found", id);
                throw new NotFoundException("Event not found.");
            }

            if (!_currentUserService.IsAdmin() && entity.OrganizerId != _currentUserService.GetUserId())
                throw new ClientException("You are not the organizer of this event.");

            if (entity.Status == EventStatus.Cancelled)
                throw new ClientException("Cancelled events cannot be edited.");

            var categoryExists = await _dbContext.Categories.AnyAsync(c => c.Id == request.CategoryId);
            if (!categoryExists)
                throw new NotFoundException("Category not found.");

            var venueExists = await _dbContext.Venues.AnyAsync(v => v.Id == request.VenueId);
            if (!venueExists)
                throw new NotFoundException("Venue not found.");

            _mapper.Map(request, entity);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Event {EventId} updated successfully", id);
            return _mapper.Map<EventResponse>(entity);
        }

        public override async Task DeleteAsync(int id)
        {
            _logger.LogInformation("Deleting event {EventId}", id);
            var entity = await _dbContext.Events.FirstOrDefaultAsync(e => e.Id == id);

            if (entity == null)
            {
                _logger.LogWarning("Event {EventId} not found", id);
                throw new NotFoundException("Event not found.");
            }

            if (!_currentUserService.IsAdmin() && entity.OrganizerId != _currentUserService.GetUserId())
                throw new ClientException("You are not the organizer of this event.");

            var hasPaidOrders = await _dbContext.Orders.AnyAsync(o => o.EventId == id && o.Status == OrderStatus.Paid);
            if (hasPaidOrders)
            {
                _logger.LogWarning("Event {EventId} cannot be deleted - has paid orders", id);
                throw new ClientException("Event cannot be deleted because it has paid orders.");
            }

            entity.IsDeleted = true;
            entity.DeletedAt = DateTime.UtcNow;
            _eventStateMachine.Transition(entity, EventStatus.Cancelled);

            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("Event {EventId} deleted (soft) successfully", id);
        }

        public async Task<EventResponse> ActivateAsync(int id)
        {
            _logger.LogInformation("Activating event {EventId}", id);
            var entity = await _dbContext.Events
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.Organizer)
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (entity == null)
            {
                _logger.LogWarning("Event {EventId} not found", id);
                throw new NotFoundException("Event not found.");
            }

            if (!_currentUserService.IsAdmin() && entity.OrganizerId != _currentUserService.GetUserId())
                throw new ClientException("Access denied.");

            var hasTicketTypes = await _dbContext.TicketTypes.AnyAsync(tt => tt.EventId == id);
            if (!hasTicketTypes)
                throw new ClientException("Event must have at least one ticket type before activation.");

            _eventStateMachine.Transition(entity, EventStatus.Active);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Event {EventId} activated successfully", id);
            return _mapper.Map<EventResponse>(entity);
        }

        public async Task<EventResponse> CancelAsync(int id)
        {
            _logger.LogInformation("Cancelling event {EventId}", id);
            var entity = await _dbContext.Events
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.Organizer)
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (entity == null)
            {
                _logger.LogWarning("Event {EventId} not found", id);
                throw new NotFoundException("Event not found.");
            }

            if (!_currentUserService.IsAdmin() && entity.OrganizerId != _currentUserService.GetUserId())
                throw new ClientException("Access denied.");

            _eventStateMachine.Transition(entity, EventStatus.Cancelled);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Event {EventId} cancelled successfully", id);
            return _mapper.Map<EventResponse>(entity);
        }

        public async Task<EventResponse> CompleteAsync(int id)
        {
            _logger.LogInformation("Completing event {EventId}", id);
            var entity = await _dbContext.Events
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.Organizer)
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (entity == null)
            {
                _logger.LogWarning("Event {EventId} not found", id);
                throw new NotFoundException("Event not found.");
            }

            _eventStateMachine.Transition(entity, EventStatus.Completed);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Event {EventId} completed successfully", id);
            return _mapper.Map<EventResponse>(entity);
        }
    }
}
