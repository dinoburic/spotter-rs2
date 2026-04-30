using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;
using Spotter.Services.StateMachines;

namespace Spotter.Services
{
    public class ReservationService : IReservationService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly ReservationStateMachine _reservationStateMachine;
        private readonly INotificationService _notificationService;
        private readonly IValidator<ReservationInsertRequest> _validator;

        public ReservationService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            ReservationStateMachine reservationStateMachine,
            INotificationService notificationService,
            IValidator<ReservationInsertRequest> validator)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _reservationStateMachine = reservationStateMachine;
            _notificationService = notificationService;
            _validator = validator;
        }

        public async Task<PageResult<ReservationResponse>> GetAllAsync(ReservationSearch? search = null)
        {
            var query = _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .Where(r => !r.IsDeleted)
                .AsQueryable();

            if (!_currentUserService.IsAdmin())
            {
                query = query.Where(r => r.UserId == _currentUserService.GetUserId());
            }

            if (search != null)
            {
                if (search.EventId.HasValue)
                    query = query.Where(r => r.EventId == search.EventId.Value);

                if (search.UserId.HasValue && _currentUserService.IsAdmin())
                    query = query.Where(r => r.UserId == search.UserId.Value);

                if (search.Status.HasValue)
                    query = query.Where(r => r.Status == search.Status.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = Math.Min(search?.PageSize ?? 20, 100);

            int? totalCount = null;
            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            var reservations = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<ReservationResponse>
            {
                Items = reservations.Select(r => _mapper.Map<ReservationResponse>(r)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<ReservationResponse> GetByIdAsync(int id)
        {
            var reservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            if (!_currentUserService.IsAdmin() && reservation.UserId != _currentUserService.GetUserId())
                throw new ClientException("Access denied.");

            return _mapper.Map<ReservationResponse>(reservation);
        }

        public async Task<ReservationResponse> CreateAsync(ReservationInsertRequest request)
        {
            await _validator.ValidateAndThrowAsync(request);

            var eventEntity = await _dbContext.Events
                .FirstOrDefaultAsync(e => e.Id == request.EventId && !e.IsDeleted);

            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            if (eventEntity.Status != EventStatus.Active)
                throw new ClientException("Reservations can only be made for active events.");

            var userId = _currentUserService.GetUserId();
            var hasDuplicate = await _dbContext.Reservations.AnyAsync(r =>
                r.UserId == userId &&
                r.EventId == request.EventId &&
                !r.IsDeleted &&
                r.Status != ReservationStatus.Cancelled);

            if (hasDuplicate)
                throw new ClientException("You already have an active reservation for this event.");

            var reservation = new Reservation
            {
                UserId = userId,
                EventId = request.EventId,
                Status = ReservationStatus.Pending,
                AuditNote = request.Note,
                CreatedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            _dbContext.Reservations.Add(reservation);
            await _dbContext.SaveChangesAsync();

            await _notificationService.CreateAsync(
                userId: userId,
                title: "Reservation Submitted",
                body: $"Your reservation for {eventEntity.Title} is pending approval.",
                type: NotificationType.General,
                referenceId: reservation.Id.ToString()
            );

            var createdReservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .FirstAsync(r => r.Id == reservation.Id);

            return _mapper.Map<ReservationResponse>(createdReservation);
        }

        public async Task<ReservationResponse> ConfirmAsync(int id, string? auditNote)
        {
            if (!_currentUserService.IsAdmin())
                throw new ClientException("Only admins can confirm reservations.");

            var reservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            _reservationStateMachine.Transition(reservation, ReservationStatus.Confirmed);
            reservation.ApprovedByUserId = _currentUserService.GetUserId();
            reservation.AuditNote = auditNote;

            await _dbContext.SaveChangesAsync();

            await _notificationService.CreateAsync(
                userId: reservation.UserId,
                title: "Reservation Confirmed",
                body: $"Your reservation for {reservation.Event.Title} has been confirmed.",
                type: NotificationType.ReservationConfirmed,
                referenceId: reservation.Id.ToString()
            );

            reservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .FirstAsync(r => r.Id == id);

            return _mapper.Map<ReservationResponse>(reservation);
        }

        public async Task<ReservationResponse> CancelAsync(int id, string? auditNote)
        {
            var reservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            var isAdmin = _currentUserService.IsAdmin();
            var userId = _currentUserService.GetUserId();

            if (!isAdmin && reservation.UserId != userId)
                throw new ClientException("Access denied.");

            _reservationStateMachine.Transition(reservation, ReservationStatus.Cancelled);
            reservation.AuditNote = auditNote;

            if (isAdmin && reservation.UserId != userId)
            {
                reservation.ApprovedByUserId = userId;

                await _notificationService.CreateAsync(
                    userId: reservation.UserId,
                    title: "Reservation Cancelled",
                    body: $"Your reservation for {reservation.Event.Title} has been cancelled.",
                    type: NotificationType.ReservationCancelled,
                    referenceId: reservation.Id.ToString()
                );
            }

            await _dbContext.SaveChangesAsync();

            reservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .FirstAsync(r => r.Id == id);

            return _mapper.Map<ReservationResponse>(reservation);
        }

        public async Task<ReservationResponse> CompleteAsync(int id)
        {
            if (!_currentUserService.IsAdmin())
                throw new ClientException("Only admins can complete reservations.");

            var reservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            _reservationStateMachine.Transition(reservation, ReservationStatus.Completed);
            reservation.ApprovedByUserId = _currentUserService.GetUserId();

            await _dbContext.SaveChangesAsync();

            reservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .FirstAsync(r => r.Id == id);

            return _mapper.Map<ReservationResponse>(reservation);
        }
    }
}
