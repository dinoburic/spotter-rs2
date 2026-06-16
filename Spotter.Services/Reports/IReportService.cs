using Spotter.Model.Responses;

namespace Spotter.Services
{
    public interface IReportService
    {
        Task<FinancialReportResponse> GetFinancialReportAsync(DateTime? from, DateTime? to, int? categoryId);
        Task<GuestListResponse> GetGuestListAsync(DateTime? from, DateTime? to, int? categoryId, int? eventId);
    }
}
