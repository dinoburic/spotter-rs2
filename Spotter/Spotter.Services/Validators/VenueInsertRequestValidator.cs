using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class VenueInsertRequestValidator : AbstractValidator<VenueInsertRequest>
    {
        public VenueInsertRequestValidator()
        {
            RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
            RuleFor(x => x.Address).NotEmpty().MaximumLength(500);
            RuleFor(x => x.CityId).GreaterThan(0);
        }
    }
}
