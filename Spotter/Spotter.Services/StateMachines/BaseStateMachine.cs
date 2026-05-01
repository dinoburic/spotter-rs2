using Spotter.Model.Exceptions;

namespace Spotter.Services.StateMachines
{
    public abstract class BaseStateMachine<TEntity, TStatus> where TStatus : Enum
    {
        protected abstract Dictionary<TStatus, TStatus[]> AllowedTransitions { get; }

        public void Transition(TEntity entity, TStatus target)
        {
            var current = GetCurrentStatus(entity);
            if (!AllowedTransitions.TryGetValue(current, out var allowed) || !allowed.Contains(target))
                throw new ClientException($"Cannot transition from {current} to {target}.");
            ApplyTransition(entity, target);
        }

        protected abstract TStatus GetCurrentStatus(TEntity entity);
        protected abstract void ApplyTransition(TEntity entity, TStatus target);
    }
}
