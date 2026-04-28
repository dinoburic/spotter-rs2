using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class CityInsertRequestValidator : AbstractValidator<CityInsertRequest>
    {
        public CityInsertRequestValidator()
        {
            RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
            RuleFor(x => x.Country).NotEmpty().MaximumLength(100);
        }
    }
}
