using Spotter.Model.Enums;
using Spotter.Services.Database;

namespace Spotter.Services.StateMachines
{
    public class TicketStateMachine : BaseStateMachine<Ticket, TicketStatus>
    {
        protected override Dictionary<TicketStatus, TicketStatus[]> AllowedTransitions => new()
        {
            { TicketStatus.Active, new[] { TicketStatus.Used, TicketStatus.Cancelled } },
            { TicketStatus.Used, Array.Empty<TicketStatus>() },
            { TicketStatus.Cancelled, Array.Empty<TicketStatus>() }
        };

        protected override TicketStatus GetCurrentStatus(Ticket entity)
        {
            return entity.Status;
        }

        protected override void ApplyTransition(Ticket entity, TicketStatus target)
        {
            entity.Status = target;
            if (target == TicketStatus.Used)
                entity.UsedAt = DateTime.UtcNow;
        }
    }
}
