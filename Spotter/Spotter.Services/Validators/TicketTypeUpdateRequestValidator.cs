using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class TicketTypeUpdateRequestValidator : AbstractValidator<TicketTypeUpdateRequest>
    {
        public TicketTypeUpdateRequestValidator()
        {
            RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
            RuleFor(x => x.Price).GreaterThan(0).LessThanOrEqualTo(10000);
            RuleFor(x => x.TotalQuantity).GreaterThan(0);
        }
    }
}
