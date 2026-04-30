using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class ReviewInsertRequestValidator : AbstractValidator<ReviewInsertRequest>
    {
        public ReviewInsertRequestValidator()
        {
            RuleFor(x => x.EventId).GreaterThan(0);
            RuleFor(x => x.Rating).InclusiveBetween(1, 5);
            RuleFor(x => x.Comment).MaximumLength(1000).When(x => x.Comment != null);
        }
    }
}
