using Spotter.Model.Enums;
using Spotter.Services.Database;

namespace Spotter.Services.StateMachines
{
    public class EventStateMachine : BaseStateMachine<Event, EventStatus>
    {
        protected override Dictionary<EventStatus, EventStatus[]> AllowedTransitions => new()
        {
            { EventStatus.Draft, new[] { EventStatus.Active, EventStatus.Cancelled } },
            { EventStatus.Active, new[] { EventStatus.Cancelled, EventStatus.Completed } },
            { EventStatus.Cancelled, Array.Empty<EventStatus>() },
            { EventStatus.Completed, Array.Empty<EventStatus>() }
        };

        protected override EventStatus GetCurrentStatus(Event entity)
        {
            return entity.Status;
        }

        protected override void ApplyTransition(Event entity, EventStatus target)
        {
            entity.Status = target;
        }
    }
}
