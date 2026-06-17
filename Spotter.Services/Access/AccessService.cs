using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Spotter.Common.Services.CryptoService;
using Spotter.Model.Access;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Services.Database;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Spotter.Services
{
    public class AccessService : IAccessService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IUserService _userService;
        private readonly IRefreshTokenService _refreshTokenService;
        private readonly ICryptoService _cryptoService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AccessService> _logger;
        private readonly IValidator<UserLoginRequest> _loginValidator;
        private readonly IValidator<RegisterRequest> _registerValidator;

        public AccessService(
            SpotterDbContext dbContext,
            IUserService userService,
            IRefreshTokenService refreshTokenService,
            ICryptoService cryptoService,
            IConfiguration configuration,
            ILogger<AccessService> logger,
            IValidator<UserLoginRequest> loginValidator,
            IValidator<RegisterRequest> registerValidator)
        {
            _dbContext = dbContext;
            _userService = userService;
            _refreshTokenService = refreshTokenService;
            _cryptoService = cryptoService;
            _configuration = configuration;
            _logger = logger;
            _loginValidator = loginValidator;
            _registerValidator = registerValidator;
        }

        public async Task<UserLoginResponse> LoginAsync(UserLoginRequest request)
        {
            await _loginValidator.ValidateAndThrowAsync(request);

            var user = await _userService.GetByUsernameAsync(request.Username);
            if (user == null)
                throw new ClientException("Invalid username or password.");

            var hash = _cryptoService.GenerateHash(request.Password, user.PasswordSalt);
            if (hash != user.PasswordHash)
                throw new ClientException("Invalid username or password.");

            var accessToken = GenerateToken(user.Id, user.Username, user.Role ?? "User");
            var refreshToken = Guid.NewGuid().ToString("N");

            await _refreshTokenService.InsertAsync(new RefreshToken
            {
                UserId = user.Id,
                Token = refreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            });

            return new UserLoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                UserId = user.Id,
                Username = user.Username,
                Role = user.Role ?? "User"
            };
        }

        public async Task<UserLoginResponse> LoginWithRefreshTokenAsync(string refreshToken)
        {
            var storedToken = await _refreshTokenService.GetStoredTokenAsync(refreshToken);
            if (storedToken == null)
                throw new ClientException("Invalid or expired refresh token.");

            var user = await _userService.GetWithRoleByIdAsync(storedToken.UserId);
            if (user == null)
                throw new NotFoundException("User not found.");

            await _refreshTokenService.DeleteAllUserRefreshTokensAsync(storedToken.UserId);

            var accessToken = GenerateToken(user.Id, user.Username, user.Role ?? "User");
            var newRefreshToken = Guid.NewGuid().ToString("N");

            await _refreshTokenService.InsertAsync(new RefreshToken
            {
                UserId = user.Id,
                Token = newRefreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            });

            return new UserLoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = newRefreshToken,
                UserId = user.Id,
                Username = user.Username,
                Role = user.Role ?? "User"
            };
        }

        public async Task LogoutAsync(string accessToken, string refreshToken)
        {
            int userId = 0;
            try
            {
                var handler = new JwtSecurityTokenHandler();
                var token = handler.ReadJwtToken(accessToken);
                var jti = token.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Jti)?.Value;
                var sub = token.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Sub)?.Value;
                var exp = token.ValidTo;

                if (!string.IsNullOrEmpty(jti) && int.TryParse(sub, out userId))
                {
                    _dbContext.InvalidatedTokens.Add(new InvalidatedToken
                    {
                        UserId = userId,
                        TokenJti = jti,
                        ExpiresAt = exp,
                        InvalidatedAt = DateTime.UtcNow
                    });
                    await _dbContext.SaveChangesAsync();
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to parse access token during logout");
            }

            if (userId > 0)
                await _refreshTokenService.DeleteAllUserRefreshTokensAsync(userId);
        }

        public async Task<UserLoginResponse> RegisterAsync(RegisterRequest request)
        {
            await _registerValidator.ValidateAndThrowAsync(request);

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username))
                throw new ClientException("Username is already taken.");

            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
                throw new ClientException("Email is already in use.");

            if (!await _dbContext.Cities.AnyAsync(c => c.Id == request.CityId))
                throw new NotFoundException("City not found.");

            var salt = _cryptoService.GenerateSlat();
            var hash = _cryptoService.GenerateHash(request.Password, salt);

            var userRole = await _dbContext.Roles.FirstOrDefaultAsync(r => r.Name == "User");
            if (userRole == null)
                throw new NotFoundException("Default user role not found.");

            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Username = request.Username,
                Email = request.Email,
                PasswordHash = hash,
                PasswordSalt = salt,
                PhoneNumber = request.PhoneNumber,
                CityId = request.CityId,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            await using var transaction = await _dbContext.Database.BeginTransactionAsync();
            try
            {
                _dbContext.Users.Add(user);
                await _dbContext.SaveChangesAsync();

                _dbContext.UserRoles.Add(new UserRole
                {
                    UserId = user.Id,
                    RoleId = userRole.Id,
                    DateAssigned = DateTime.UtcNow
                });
                await _dbContext.SaveChangesAsync();

                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }

            return await LoginAsync(new UserLoginRequest
            {
                Username = request.Username,
                Password = request.Password
            });
        }

        private string GenerateToken(int userId, string username, string role)
        {
            var secretKey = _configuration["Jwt:Secret"] ?? _configuration["JwtToken:SecretKey"] ?? string.Empty;
            var issuer = _configuration["Jwt:Issuer"] ?? _configuration["JwtToken:Issuer"];
            var audience = _configuration["Jwt:Audience"] ?? _configuration["JwtToken:Audience"];

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
                new Claim(JwtRegisteredClaimNames.UniqueName, username),
                new Claim(ClaimTypes.Role, role),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(60),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
