using System;
using System.Collections.Generic;
using System.Linq;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;
using FluentValidation;

namespace Spotter.Services
{
    public class ProductTypeService : BaseCRUDService<ProductType, ProductTypeResponse, ProductTypeSearch, ProductTypeInsertRequest, ProductTypeUpdateRequest>, IProductTypeService
    {
        public ProductTypeService(SpotterDbContext dbContext, MapsterMapper.IMapper mapper, IValidator<ProductTypeInsertRequest> insertValidator, IValidator<ProductTypeUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override IEnumerable<ProductType> ApplyFilters(IEnumerable<ProductType> query, ProductTypeSearch? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(pt => pt.Name.Contains(search.Name, StringComparison.OrdinalIgnoreCase));
                }

                if (search.IsActive.HasValue)
                {
                    query = query.Where(pt => pt.IsActive == search.IsActive.Value);
                }
            }

            return query;
        }
    }
}
