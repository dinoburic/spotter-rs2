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
            RuleFor(x => x.Items)
                .Must(items => items.Select(i => i.TicketTypeId).Distinct().Count() == items.Count)
                .WithMessage("Duplicate ticket types in the same order are not allowed. Increase quantity instead.");
            RuleForEach(x => x.Items).ChildRules(item =>
            {
                item.RuleFor(i => i.TicketTypeId).GreaterThan(0);
                item.RuleFor(i => i.Quantity).GreaterThan(0).LessThanOrEqualTo(20);
            });
        }
    }
}
