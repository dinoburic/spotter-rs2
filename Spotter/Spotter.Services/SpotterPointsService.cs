using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class SpotterPointsService : ISpotterPointsService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<SpotterPointsService> _logger;

        public SpotterPointsService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            ILogger<SpotterPointsService> logger)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<PageResult<SpotterPointsResponse>> GetLedgerAsync(SpotterPointsSearch? search = null)
        {
            var query = _dbContext.SpotterPoints.AsQueryable();

            if (!_currentUserService.IsAdmin())
            {
                query = query.Where(sp => sp.UserId == _currentUserService.GetUserId());
            }
            else if (search?.UserId.HasValue == true)
            {
                query = query.Where(sp => sp.UserId == search.UserId.Value);
            }

            if (search?.Source.HasValue == true)
            {
                query = query.Where(sp => sp.Source == search.Source.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = Math.Min(search?.PageSize ?? 20, 100);

            int? totalCount = null;
            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            var entries = await query
                .OrderByDescending(sp => sp.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<SpotterPointsResponse>
            {
                Items = entries.Select(sp => _mapper.Map<SpotterPointsResponse>(sp)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<PointsBalanceResponse> GetBalanceAsync(int? userId = null)
        {
            var targetUserId = userId ?? _currentUserService.GetUserId();

            if (!_currentUserService.IsAdmin() && targetUserId != _currentUserService.GetUserId())
            {
                throw new ClientException("Access denied.");
            }

            var balance = await _dbContext.SpotterPoints
                .Where(sp => sp.UserId == targetUserId)
                .SumAsync(sp => sp.Delta);

            var totalEarned = await _dbContext.SpotterPoints
                .Where(sp => sp.UserId == targetUserId && sp.Delta > 0)
                .SumAsync(sp => sp.Delta);

            var totalRedeemed = await _dbContext.SpotterPoints
                .Where(sp => sp.UserId == targetUserId && sp.Delta < 0)
                .SumAsync(sp => Math.Abs(sp.Delta));

            return new PointsBalanceResponse
            {
                UserId = targetUserId,
                Balance = balance,
                TotalEarned = totalEarned,
                TotalRedeemed = totalRedeemed
            };
        }

        public async Task<SpotterPointsResponse> EarnAsync(int userId, int delta, PointSource source, string? referenceId = null, string? description = null)
        {
            _logger.LogInformation("Earning {Delta} points for user {UserId} from {Source}", delta, userId, source);
            var user = await _dbContext.Users.FindAsync(userId);
            if (user == null)
            {
                _logger.LogWarning("User {UserId} not found", userId);
                throw new NotFoundException("User not found.");
            }

            if (delta <= 0)
            {
                throw new ClientException("Delta must be positive for earning points.");
            }

            var entry = new SpotterPoints
            {
                UserId = userId,
                Delta = delta,
                Source = source,
                ReferenceId = referenceId != null ? int.TryParse(referenceId, out var refId) ? refId : null : null,
                Description = description,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SpotterPoints.Add(entry);
            user.SpotterPointsBalance += delta;
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("User {UserId} earned {Delta} points", userId, delta);
            return _mapper.Map<SpotterPointsResponse>(entry);
        }

        public async Task RedeemAsync(int userId, int points, string? referenceId = null)
        {
            _logger.LogInformation("Redeeming {Points} points for user {UserId}", points, userId);
            var balance = await _dbContext.SpotterPoints
                .Where(sp => sp.UserId == userId)
                .SumAsync(sp => sp.Delta);

            if (balance < points)
            {
                _logger.LogWarning("User {UserId} has insufficient points ({Balance}) to redeem {Points}", userId, balance, points);
                throw new ClientException($"Insufficient points. Available: {balance}.");
            }

            var user = await _dbContext.Users.FindAsync(userId);
            if (user == null)
            {
                _logger.LogWarning("User {UserId} not found", userId);
                throw new NotFoundException("User not found.");
            }

            var entry = new SpotterPoints
            {
                UserId = userId,
                Delta = -points,
                Source = PointSource.Redemption,
                ReferenceId = referenceId != null ? int.TryParse(referenceId, out var refId) ? refId : null : null,
                Description = "Points redeemed",
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SpotterPoints.Add(entry);
            user.SpotterPointsBalance -= points;
            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("User {UserId} redeemed {Points} points", userId, points);
        }
    }
}
