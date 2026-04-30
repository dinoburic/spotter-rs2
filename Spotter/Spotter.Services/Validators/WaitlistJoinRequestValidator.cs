using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class WaitlistJoinRequestValidator : AbstractValidator<WaitlistJoinRequest>
    {
        public WaitlistJoinRequestValidator()
        {
            RuleFor(x => x.EventId).GreaterThan(0);
            RuleFor(x => x.TicketTypeId).GreaterThan(0);
        }
    }
}
