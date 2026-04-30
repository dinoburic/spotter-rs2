using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class OrderInsertRequestValidator : AbstractValidator<OrderInsertRequest>
    {
        public OrderInsertRequestValidator()
        {
            RuleFor(x => x.EventId).GreaterThan(0);
            RuleFor(x => x.Items).NotEmpty().Must(items => items.Count > 0).WithMessage("Order must contain at least one item.");
            RuleForEach(x => x.Items).ChildRules(item =>
            {
                item.RuleFor(i => i.TicketTypeId).GreaterThan(0);
                item.RuleFor(i => i.Quantity).GreaterThan(0).LessThanOrEqualTo(20);
            });
        }
    }
}
