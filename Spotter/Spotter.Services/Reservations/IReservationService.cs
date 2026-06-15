using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IReservationService
    {
        Task<PageResult<ReservationResponse>> GetAllAsync(ReservationSearch? search = null);
        Task<ReservationResponse> GetByIdAsync(int id);
        Task<ReservationResponse> CreateAsync(ReservationInsertRequest request);
        Task<ReservationResponse> ConfirmAsync(int id, string? auditNote);
        Task<ReservationResponse> CancelAsync(int id, string? auditNote);
        Task<ReservationResponse> CompleteAsync(int id);
    }
}
