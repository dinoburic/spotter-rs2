using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class EventService : BaseCRUDService<Event, EventResponse, EventSearch, EventInsertRequest, EventUpdateRequest>, IEventService
    {
        private readonly ICurrentUserService _currentUserService;

        public EventService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<EventInsertRequest> insertValidator,
            IValidator<EventUpdateRequest> updateValidator,
            ICurrentUserService currentUserService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _currentUserService = currentUserService;
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
            await _insertValidator.ValidateAndThrowAsync(request);

            var categoryExists = await _dbContext.Categories.AnyAsync(c => c.Id == request.CategoryId);
            if (!categoryExists)
                throw new NotFoundException("Category not found.");

            var venueExists = await _dbContext.Venues.AnyAsync(v => v.Id == request.VenueId);
            if (!venueExists)
                throw new NotFoundException("Venue not found.");

            var entity = _mapper.Map<Event>(request);
            entity.OrganizerId = _currentUserService.GetUserId();
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

            return _mapper.Map<EventResponse>(createdEvent);
        }

        public override async Task<EventResponse> UpdateAsync(int id, EventUpdateRequest request)
        {
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.Events
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.Organizer)
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (entity == null)
                throw new NotFoundException("Event not found.");

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

            return _mapper.Map<EventResponse>(entity);
        }

        public override async Task DeleteAsync(int id)
        {
            var entity = await _dbContext.Events.FirstOrDefaultAsync(e => e.Id == id);

            if (entity == null)
                throw new NotFoundException("Event not found.");

            if (!_currentUserService.IsAdmin() && entity.OrganizerId != _currentUserService.GetUserId())
                throw new ClientException("You are not the organizer of this event.");

            var hasPaidOrders = await _dbContext.Orders.AnyAsync(o => o.EventId == id && o.Status == OrderStatus.Paid);
            if (hasPaidOrders)
                throw new ClientException("Event cannot be deleted because it has paid orders.");

            entity.IsDeleted = true;
            entity.DeletedAt = DateTime.UtcNow;
            entity.Status = EventStatus.Cancelled;

            await _dbContext.SaveChangesAsync();
        }

        public async Task<EventResponse> ActivateAsync(int id)
        {
            var entity = await _dbContext.Events
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.Organizer)
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (entity == null)
                throw new NotFoundException("Event not found.");

            if (entity.Status != EventStatus.Draft)
                throw new ClientException("Only draft events can be activated.");

            var hasTicketTypes = await _dbContext.TicketTypes.AnyAsync(tt => tt.EventId == id);
            if (!hasTicketTypes)
                throw new ClientException("Event must have at least one ticket type before activation.");

            entity.Status = EventStatus.Active;
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<EventResponse>(entity);
        }

        public async Task<EventResponse> CancelAsync(int id)
        {
            var entity = await _dbContext.Events
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.Organizer)
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (entity == null)
                throw new NotFoundException("Event not found.");

            if (entity.Status == EventStatus.Cancelled)
                throw new ClientException("Event is already cancelled.");

            if (entity.Status == EventStatus.Completed)
                throw new ClientException("Completed events cannot be cancelled.");

            entity.Status = EventStatus.Cancelled;
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<EventResponse>(entity);
        }
    }
}
