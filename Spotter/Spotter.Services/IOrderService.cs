using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IOrderService
    {
        Task<PageResult<OrderResponse>> GetAllAsync(OrderSearch? search = null);
        Task<OrderResponse> GetByIdAsync(int id);
        Task<OrderResponse> CreateOrderAsync(OrderInsertRequest request);
        Task<OrderResponse> MarkAsPaidAsync(int id);
        Task<OrderResponse> RefundAsync(int id);
        Task CancelAsync(int id);
    }
}
