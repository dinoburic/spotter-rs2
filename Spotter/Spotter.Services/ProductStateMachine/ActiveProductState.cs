using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Services.Database;
using Humanizer;
using MapsterMapper;

namespace Spotter.Services.ProductStateMachine
{   
    public class ActiveProductState : BaseProductState
    {
        public ActiveProductState(SpotterDbContext dbContext, IMapper mapper, IServiceProvider serviceProvider) : base(dbContext, mapper, serviceProvider)
        {
            
        }

        override public async Task<ProductResponse> DeactivateAsync(int id)
        {
            var entity = await DbContext.Products.FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"Product with id {id} not found.");
            }

            entity.ProductState = nameof(DraftProductState);    
            await DbContext.SaveChangesAsync();

            return Mapper.Map<ProductResponse>(entity);
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(DeactivateAsync) };
        }
    }
}