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
    public class TicketTypeService : BaseCRUDService<TicketType, TicketTypeResponse, TicketTypeSearch, TicketTypeInsertRequest, TicketTypeUpdateRequest>, ITicketTypeService
    {
        public TicketTypeService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<TicketTypeInsertRequest> insertValidator,
            IValidator<TicketTypeUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override Task<IQueryable<TicketType>> IncludeRelatedEntitiesAsync(TicketTypeSearch? search, IQueryable<TicketType> query)
        {
            query = query.Include(tt => tt.Event);
            return Task.FromResult(query);
        }

        protected override IQueryable<TicketType> ApplyFilters(IQueryable<TicketType> query, TicketTypeSearch? search)
        {
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
            await _insertValidator.ValidateAndThrowAsync(request);

            var eventEntity = await _dbContext.Events.FirstOrDefaultAsync(e => e.Id == request.EventId);
            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            if (eventEntity.Status == EventStatus.Cancelled)
                throw new ClientException("Cannot add ticket types to a cancelled event.");

            var entity = _mapper.Map<TicketType>(request);
            entity.SoldQuantity = 0;

            _dbContext.TicketTypes.Add(entity);
            await _dbContext.SaveChangesAsync();

            var createdEntity = await _dbContext.TicketTypes
                .Include(tt => tt.Event)
                .FirstAsync(tt => tt.Id == entity.Id);

            return _mapper.Map<TicketTypeResponse>(createdEntity);
        }

        public override async Task<TicketTypeResponse> UpdateAsync(int id, TicketTypeUpdateRequest request)
        {
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.TicketTypes
                .Include(tt => tt.Event)
                .FirstOrDefaultAsync(tt => tt.Id == id);

            if (entity == null)
                throw new NotFoundException("TicketType not found.");

            if (request.TotalQuantity < entity.SoldQuantity)
                throw new ClientException("TotalQuantity cannot be less than the number of already sold tickets.");

            _mapper.Map(request, entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<TicketTypeResponse>(entity);
        }

        public override async Task DeleteAsync(int id)
        {
            var entity = await _dbContext.TicketTypes.FirstOrDefaultAsync(tt => tt.Id == id);

            if (entity == null)
                throw new NotFoundException("TicketType not found.");

            if (entity.SoldQuantity > 0)
                throw new ClientException("Cannot delete a ticket type that has sold tickets.");

            _dbContext.TicketTypes.Remove(entity);
            await _dbContext.SaveChangesAsync();
        }
    }
}
