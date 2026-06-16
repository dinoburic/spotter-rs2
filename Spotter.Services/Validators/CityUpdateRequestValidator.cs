using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class CityUpdateRequestValidator : AbstractValidator<CityUpdateRequest>
    {
        public CityUpdateRequestValidator()
        {
            RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
            RuleFor(x => x.Country).NotEmpty().MaximumLength(100);
        }
    }
}
