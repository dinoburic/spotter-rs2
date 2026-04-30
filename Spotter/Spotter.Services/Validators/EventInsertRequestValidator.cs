using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class EventInsertRequestValidator : AbstractValidator<EventInsertRequest>
    {
        public EventInsertRequestValidator()
        {
            RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
            RuleFor(x => x.Description).NotEmpty().MaximumLength(2000);
            RuleFor(x => x.CategoryId).GreaterThan(0);
            RuleFor(x => x.VenueId).GreaterThan(0);
            RuleFor(x => x.StartsAt).Must(d => d > DateTime.UtcNow).WithMessage("StartsAt must be a future date.");
            RuleFor(x => x.EndsAt).GreaterThan(x => x.StartsAt).WithMessage("EndsAt must be after StartsAt.");
            RuleFor(x => x.TotalCapacity).GreaterThan(0).LessThanOrEqualTo(100000);
            RuleFor(x => x.CoverImageUrl).MaximumLength(500).When(x => x.CoverImageUrl != null);
        }
    }
}
