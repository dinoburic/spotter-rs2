using Spotter.Model.Enums;
using Spotter.Services.Database;

namespace Spotter.Services.StateMachines
{
    public class ReservationStateMachine : BaseStateMachine<Reservation, ReservationStatus>
    {
        protected override Dictionary<ReservationStatus, ReservationStatus[]> AllowedTransitions => new()
        {
            { ReservationStatus.Pending, new[] { ReservationStatus.Confirmed, ReservationStatus.Cancelled } },
            { ReservationStatus.Confirmed, new[] { ReservationStatus.Completed, ReservationStatus.Cancelled } },
            { ReservationStatus.Cancelled, Array.Empty<ReservationStatus>() },
            { ReservationStatus.Completed, Array.Empty<ReservationStatus>() }
        };

        protected override ReservationStatus GetCurrentStatus(Reservation entity)
        {
            return entity.Status;
        }

        protected override void ApplyTransition(Reservation entity, ReservationStatus target)
        {
            entity.Status = target;
            if (target == ReservationStatus.Confirmed)
                entity.ApprovedAt = DateTime.UtcNow;
        }
    }
}
