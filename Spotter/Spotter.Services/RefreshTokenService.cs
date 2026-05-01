using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Exceptions;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class RefreshTokenService : IRefreshTokenService
    {
        private readonly SpotterDbContext _context;
        private readonly DbSet<RefreshToken> _refreshTokens;
        private readonly ILogger<RefreshTokenService> _logger;

        public RefreshTokenService(SpotterDbContext context, ILogger<RefreshTokenService> logger)
        {
            _context = context;
            _refreshTokens = _context.RefreshTokens;
            _logger = logger;
        }

        public async Task<RefreshToken> GetStoredTokenAsync(string refreshToken)
        {
            var token = await _refreshTokens.FirstOrDefaultAsync(rt => rt.Token == refreshToken);

            if (token == null)
            {
                _logger.LogWarning("Refresh token not found");
                throw new ClientException("Refresh token not found.");
            }

            return token;
        }

        public async Task InsertAsync(RefreshToken refreshToken)
        {
            _logger.LogInformation("Inserting refresh token for user {UserId}", refreshToken.UserId);
            await _context.RefreshTokens.AddAsync(refreshToken);
            await _context.SaveChangesAsync();
        }

        public Task DeleteAllUserRefreshTokensAsync(int userId)
        {
            _logger.LogInformation("Deleting all refresh tokens for user {UserId}", userId);
            _refreshTokens.RemoveRange(_refreshTokens.Where(rt => rt.UserId == userId));
            return _context.SaveChangesAsync();
        }
    }
}
