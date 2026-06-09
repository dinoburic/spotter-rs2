using Spotter.Model.Enums;
using Spotter.Services.Database;

namespace Spotter.Services.StateMachines
{
    public class OrderStateMachine : BaseStateMachine<Order, OrderStatus>
    {
        protected override Dictionary<OrderStatus, OrderStatus[]> AllowedTransitions => new()
        {
            { OrderStatus.Pending, new[] { OrderStatus.Paid, OrderStatus.Cancelled } },
            { OrderStatus.Paid, new[] { OrderStatus.Refunded } },
            { OrderStatus.Refunded, Array.Empty<OrderStatus>() },
            { OrderStatus.Cancelled, Array.Empty<OrderStatus>() }
        };

        protected override OrderStatus GetCurrentStatus(Order entity)
        {
            return entity.Status;
        }

        protected override void ApplyTransition(Order entity, OrderStatus target)
        {
            entity.Status = target;
        }
    }
}
