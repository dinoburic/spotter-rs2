using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class ReservationInsertRequestValidator : AbstractValidator<ReservationInsertRequest>
    {
        public ReservationInsertRequestValidator()
        {
            RuleFor(x => x.EventId).GreaterThan(0);
            RuleFor(x => x.TicketTypeId).GreaterThan(0);
            RuleFor(x => x.Quantity).GreaterThan(0).LessThanOrEqualTo(10);
            RuleFor(x => x.Note).MaximumLength(500).When(x => x.Note != null);
        }
    }
}
