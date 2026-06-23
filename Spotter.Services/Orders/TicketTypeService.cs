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

namespace Spotter.Services
{
    public class TicketTypeService : BaseCRUDService<TicketType, TicketTypeResponse, TicketTypeSearch, TicketTypeInsertRequest, TicketTypeUpdateRequest>, ITicketTypeService
    {
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<TicketTypeService> _logger;

        public TicketTypeService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<TicketTypeInsertRequest> insertValidator,
            IValidator<TicketTypeUpdateRequest> updateValidator,
            ICurrentUserService currentUserService,
            ILogger<TicketTypeService> logger)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _currentUserService = currentUserService;
            _logger = logger;
        }

        protected override Task<IQueryable<TicketType>> IncludeRelatedEntitiesAsync(TicketTypeSearch? search, IQueryable<TicketType> query)
        {
            query = query.Include(tt => tt.Event);
            return Task.FromResult(query);
        }

        protected override IQueryable<TicketType> ApplyFilters(IQueryable<TicketType> query, TicketTypeSearch? search)
        {
            if (!_currentUserService.IsAdmin())
            {
                query = query.Where(tt => tt.Event.Status == EventStatus.Active && !tt.Event.IsDeleted);
            }

            if (search == null)
                return query;

            if (search.EventId.HasValue)
                query = query.Where(tt => tt.EventId == search.EventId.Value);

            if (search.TypeEnum.HasValue)
                query = query.Where(tt => tt.TypeEnum == search.TypeEnum.Value);

            return query;
        }

        public override async Task<TicketTypeResponse> InsertAsync(TicketTypeInsertRequest request)
        {
            _logger.LogInformation("Creating ticket type {Name} for event {EventId}", request.Name, request.EventId);
            await _insertValidator.ValidateAndThrowAsync(request);

            var eventEntity = await _dbContext.Events
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == request.EventId);
            if (eventEntity == null)
            {
                _logger.LogWarning("Event {EventId} not found", request.EventId);
                throw new NotFoundException("Event not found.");
            }

            var currentUserId = _currentUserService.GetUserId();
            if (!_currentUserService.IsAdmin() && eventEntity.OrganizerId != currentUserId)
                throw new ClientException("You can only add ticket types to your own events.");

            if (eventEntity.Status == EventStatus.Cancelled)
                throw new ClientException("Cannot add ticket types to a cancelled event.");

            var existingTotal = eventEntity.TicketTypes.Sum(tt => tt.TotalQuantity);
            var newTotal = existingTotal + request.TotalQuantity;

            if (newTotal > eventEntity.TotalCapacity)
                throw new ClientException($"Total ticket quantity ({newTotal}) exceeds event capacity ({eventEntity.TotalCapacity}).");

            var entity = _mapper.Map<TicketType>(request);
            entity.SoldQuantity = 0;

            _dbContext.TicketTypes.Add(entity);
            await _dbContext.SaveChangesAsync();

            var createdEntity = await _dbContext.TicketTypes
                .Include(tt => tt.Event)
                .FirstAsync(tt => tt.Id == entity.Id);

            _logger.LogInformation("Ticket type {TicketTypeId} created successfully", entity.Id);
            return _mapper.Map<TicketTypeResponse>(createdEntity);
        }

        public override async Task<TicketTypeResponse> UpdateAsync(int id, TicketTypeUpdateRequest request)
        {
            _logger.LogInformation("Updating ticket type {TicketTypeId}", id);
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.TicketTypes
                .Include(tt => tt.Event)
                .FirstOrDefaultAsync(tt => tt.Id == id);

            if (entity == null)
            {
                _logger.LogWarning("TicketType {TicketTypeId} not found", id);
                throw new NotFoundException("TicketType not found.");
            }

            var eventEntity = await _dbContext.Events
                .Include(e => e.TicketTypes)
                .FirstOrDefaultAsync(e => e.Id == entity.EventId);
            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            var currentUserId = _currentUserService.GetUserId();
            if (!_currentUserService.IsAdmin() && eventEntity.OrganizerId != currentUserId)
                throw new ClientException("You can only modify ticket types for your own events.");

            if (request.TotalQuantity < entity.SoldQuantity)
                throw new ClientException("TotalQuantity cannot be less than the number of already sold tickets.");

            var existingTotal = eventEntity.TicketTypes
                .Where(tt => tt.Id != id)
                .Sum(tt => tt.TotalQuantity);
            var newTotal = existingTotal + request.TotalQuantity;

            if (newTotal > eventEntity.TotalCapacity)
                throw new ClientException($"Total ticket quantity ({newTotal}) exceeds event capacity ({eventEntity.TotalCapacity}).");

            _mapper.Map(request, entity);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Ticket type {TicketTypeId} updated successfully", id);
            return _mapper.Map<TicketTypeResponse>(entity);
        }

        public override async Task DeleteAsync(int id)
        {
            _logger.LogInformation("Deleting ticket type {TicketTypeId}", id);
            var entity = await _dbContext.TicketTypes.FirstOrDefaultAsync(tt => tt.Id == id);

            if (entity == null)
            {
                _logger.LogWarning("TicketType {TicketTypeId} not found", id);
                throw new NotFoundException("TicketType not found.");
            }

            var eventEntity = await _dbContext.Events.FirstOrDefaultAsync(e => e.Id == entity.EventId);
            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            var currentUserId = _currentUserService.GetUserId();
            if (!_currentUserService.IsAdmin() && eventEntity.OrganizerId != currentUserId)
                throw new ClientException("You can only delete ticket types for your own events.");

            if (entity.SoldQuantity > 0)
            {
                _logger.LogWarning("TicketType {TicketTypeId} cannot be deleted - has sold tickets", id);
                throw new ClientException("Cannot delete a ticket type that has sold tickets.");
            }

            _dbContext.TicketTypes.Remove(entity);
            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("Ticket type {TicketTypeId} deleted successfully", id);
        }
    }
}
