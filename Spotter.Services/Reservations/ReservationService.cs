using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;
using Spotter.Services.StateMachines;
using System.Data;

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
        private readonly ILogger<ReservationService> _logger;

        public ReservationService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            ReservationStateMachine reservationStateMachine,
            INotificationService notificationService,
            IValidator<ReservationInsertRequest> validator,
            ILogger<ReservationService> logger)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _reservationStateMachine = reservationStateMachine;
            _notificationService = notificationService;
            _validator = validator;
            _logger = logger;
        }

        public async Task<PageResult<ReservationResponse>> GetAllAsync(ReservationSearch? search = null)
        {
            var query = _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.TicketType)
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
                .Include(r => r.TicketType)
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
            var userId = _currentUserService.GetUserId();
            _logger.LogInformation("Creating reservation for event {EventId}, ticket type {TicketTypeId} by user {UserId}", request.EventId, request.TicketTypeId, userId);

            try
            {
                await _validator.ValidateAndThrowAsync(request);

                var ticketType = await _dbContext.TicketTypes
                    .FirstOrDefaultAsync(tt => tt.Id == request.TicketTypeId && tt.EventId == request.EventId);

                if (ticketType == null)
                    throw new NotFoundException("Ticket type not found for this event.");

                var eventEntity = await _dbContext.Events
                    .FirstOrDefaultAsync(e => e.Id == request.EventId && !e.IsDeleted);

                if (eventEntity == null)
                {
                    _logger.LogWarning("Event {EventId} not found", request.EventId);
                    throw new NotFoundException("Event not found.");
                }

                if (eventEntity.Status != EventStatus.Active)
                    throw new ClientException("Reservations can only be made for active events.");

                var hasDuplicate = await _dbContext.Reservations.AnyAsync(r =>
                    r.UserId == userId &&
                    r.TicketTypeId == request.TicketTypeId &&
                    !r.IsDeleted &&
                    r.Status == ReservationStatus.Pending);

                if (hasDuplicate)
                    throw new ClientException("You already have a pending reservation for this ticket type.");

                await using var transaction = await _dbContext.Database.BeginTransactionAsync(IsolationLevel.Serializable);

                try
                {
                    var rowsAffected = await _dbContext.Database.ExecuteSqlRawAsync(
                        @"UPDATE TicketTypes
                          SET SoldQuantity = SoldQuantity + {0}
                          WHERE Id = {1}
                          AND (TotalQuantity - SoldQuantity) >= {0}",
                        request.Quantity, request.TicketTypeId);

                    if (rowsAffected == 0)
                    {
                        await transaction.RollbackAsync();
                        throw new ClientException("Not enough capacity available to reserve.");
                    }

                    var reservation = new Reservation
                    {
                        UserId = userId,
                        EventId = request.EventId,
                        TicketTypeId = request.TicketTypeId,
                        Quantity = request.Quantity,
                        Status = ReservationStatus.Pending,
                        AuditNote = request.Note,
                        CreatedAt = DateTime.UtcNow,
                        ExpiresAt = DateTime.UtcNow.AddMinutes(15),
                        IsDeleted = false
                    };

                    _dbContext.Reservations.Add(reservation);
                    await _dbContext.SaveChangesAsync();
                    await transaction.CommitAsync();

                    await _notificationService.CreateAsync(
                        userId: userId,
                        title: "Reservation Created",
                        body: $"Your reservation for {request.Quantity} {ticketType.Name} ticket(s) at {eventEntity.Title} expires in 15 minutes.",
                        type: NotificationType.General,
                        referenceId: reservation.Id.ToString()
                    );

                    var createdReservation = await _dbContext.Reservations
                        .Include(r => r.User)
                        .Include(r => r.Event)
                        .Include(r => r.TicketType)
                        .Include(r => r.ApprovedBy)
                        .FirstAsync(r => r.Id == reservation.Id);

                    _logger.LogInformation("Reservation {ReservationId} created successfully", reservation.Id);
                    return _mapper.Map<ReservationResponse>(createdReservation);
                }
                catch (ClientException)
                {
                    throw;
                }
                catch (Exception)
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            catch (Exception ex) when (ex is not ClientException and not NotFoundException)
            {
                _logger.LogError(ex, "Failed to create reservation for user {UserId}", userId);
                throw;
            }
        }

        public async Task<ReservationResponse> ConfirmAsync(int id, string? auditNote)
        {
            _logger.LogInformation("Confirming reservation {ReservationId}", id);
            if (!_currentUserService.IsAdmin())
                throw new ClientException("Only admins can confirm reservations.");

            var reservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.ApprovedBy)
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (reservation == null)
            {
                _logger.LogWarning("Reservation {ReservationId} not found", id);
                throw new NotFoundException("Reservation not found.");
            }

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

            _logger.LogInformation("Reservation {ReservationId} confirmed successfully", id);
            return _mapper.Map<ReservationResponse>(reservation);
        }

        public async Task<ReservationResponse> CancelAsync(int id, string? auditNote)
        {
            _logger.LogInformation("Cancelling reservation {ReservationId}", id);
            var reservation = await _dbContext.Reservations
                .Include(r => r.User)
                .Include(r => r.Event)
                .Include(r => r.TicketType)
                .Include(r => r.ApprovedBy)
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            var isAdmin = _currentUserService.IsAdmin();
            var userId = _currentUserService.GetUserId();

            if (!isAdmin && reservation.UserId != userId)
                throw new ClientException("Access denied.");

            if (reservation.Status == ReservationStatus.Pending && reservation.TicketType != null)
            {
                reservation.TicketType.SoldQuantity = Math.Max(0, reservation.TicketType.SoldQuantity - reservation.Quantity);
            }

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
                .Include(r => r.TicketType)
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
