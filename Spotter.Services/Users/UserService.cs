using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Common.Services.CryptoService;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace Spotter.Services
{
    public class UserService : BaseCRUDService<User, UserResponse, UserSearch, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly ICryptoService _cryptoService;
        private readonly ILogger<UserService> _logger;

        public UserService(SpotterDbContext dbContext, MapsterMapper.IMapper mapper, IValidator<UserInsertRequest> insertValidator, IValidator<UserUpdateRequest> updateValidator, ICryptoService cryptoService, ILogger<UserService> logger)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _cryptoService = cryptoService;
            _logger = logger;
        }

        protected override Task<IQueryable<User>> IncludeRelatedEntitiesAsync(UserSearch? search, IQueryable<User> query)
{
    query = query
        .Include(u => u.UserRoles)
        .ThenInclude(ur => ur.Role)
        .Include(u => u.City);
    return Task.FromResult(query);
}

        protected override IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearch? search)
        {
            query = query.Where(u => !u.IsDeleted);

            if (search == null)
                return query;

            if (!string.IsNullOrWhiteSpace(search.Email))
                query = query.Where(u => u.Email.Contains(search.Email));

            if (!string.IsNullOrWhiteSpace(search.Username))
                query = query.Where(u => u.Username.Contains(search.Username));

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(u => u.FirstName.Contains(search.Name) || u.LastName.Contains(search.Name));

            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            return query;
        }

        protected override User MapInsertRequestToEntity(UserInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);
            var salt = _cryptoService.GenerateSlat();
            entity.PasswordSalt = salt;
            entity.PasswordHash = _cryptoService.GenerateHash(request.Password, salt);
            return entity;
        }

        public override async Task<UserResponse> InsertAsync(UserInsertRequest request)
        {
            _logger.LogInformation("Creating user {Username}", request.Username);
            await _insertValidator.ValidateAndThrowAsync(request);

            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
                throw new ClientException($"Email '{request.Email}' is already in use.");

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username))
                throw new ClientException($"Username '{request.Username}' is already in use.");

            var entity = MapInsertRequestToEntity(request);
            entity.CreatedAt = DateTime.UtcNow;

            _dbContext.Users.Add(entity);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("User {UserId} created successfully", entity.Id);
            return _mapper.Map<UserResponse>(entity);
        }

        public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
        {
            _logger.LogInformation("Updating user {UserId}", id);
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.Users.FindAsync(id);
            if (entity == null)
            {
                _logger.LogWarning("User {UserId} not found", id);
                throw new NotFoundException($"User with id {id} not found.");
            }

            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email && u.Id != id))
                throw new ClientException($"Email '{request.Email}' is already in use.");

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username && u.Id != id))
                throw new ClientException($"Username '{request.Username}' is already in use.");

            MapUpdateRequestToEntity(request, entity);

            _dbContext.Users.Update(entity);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("User {UserId} updated successfully", id);
            return _mapper.Map<UserResponse>(entity);
        }

        public override async Task DeleteAsync(int id)
        {
            _logger.LogInformation("Deleting user {UserId}", id);
            var entity = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (entity == null)
            {
                _logger.LogWarning("User {UserId} not found", id);
                throw new NotFoundException($"User with id {id} not found.");
            }

            entity.IsDeleted = true;
            entity.DeletedAt = DateTime.UtcNow;
            entity.IsActive = false;
            _dbContext.Users.Update(entity);
            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("User {UserId} soft deleted successfully", id);
        }

        public async Task<UserSensitiveResponse?> GetByUsernameAsync(string username)
        {
            var user = await _dbContext.Users
                .AsNoTracking()
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username == username && u.IsActive && !u.IsDeleted);

            if (user == null)
                return null;

            var response = _mapper.Map<UserSensitiveResponse>(user);
            response.Role = user.UserRoles.FirstOrDefault()?.Role.Name;
            return response;
        }

        public async Task<UserResponse?> GetWithRoleByIdAsync(int id)
        {
            var user = await _dbContext.Users
                .AsNoTracking()
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null)
                return null;

            var response = _mapper.Map<UserResponse>(user);
            response.Role = user.UserRoles.First().Role.Name;
            return response;
        }

        public async Task ChangePasswordAsync(int userId, ChangePasswordRequest request)
        {
            _logger.LogInformation("Changing password for user {UserId}", userId);

            var validator = new Validators.ChangePasswordValidator();
            await validator.ValidateAndThrowAsync(request);

            var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                _logger.LogWarning("User {UserId} not found", userId);
                throw new NotFoundException("User not found.");
            }

            var currentHash = _cryptoService.GenerateHash(request.CurrentPassword, user.PasswordSalt);
            if (currentHash != user.PasswordHash)
            {
                _logger.LogWarning("Current password incorrect for user {UserId}", userId);
                throw new ClientException("Current password is incorrect.");
            }

            var newSalt = _cryptoService.GenerateSlat();
            user.PasswordSalt = newSalt;
            user.PasswordHash = _cryptoService.GenerateHash(request.NewPassword, newSalt);

            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("Password changed successfully for user {UserId}", userId);
        }

        public async Task<List<UserInterestResponse>> GetInterestsAsync(int userId)
        {
            var interests = await _dbContext.UserInterests
                .Include(ui => ui.Category)
                .Where(ui => ui.UserId == userId)
                .ToListAsync();

            return interests.Select(ui => new UserInterestResponse
            {
                CategoryId = ui.CategoryId,
                CategoryName = ui.Category?.Name ?? string.Empty,
                ColorHex = ui.Category?.ColorHex ?? string.Empty,
            }).ToList();
        }

        public async Task UpdateInterestsAsync(int userId, UpdateInterestsRequest request)
        {
            _logger.LogInformation("Updating interests for user {UserId}", userId);

            var existing = await _dbContext.UserInterests
                .Where(ui => ui.UserId == userId)
                .ToListAsync();

            _dbContext.UserInterests.RemoveRange(existing);

            var newInterests = request.CategoryIds.Select(categoryId => new UserInterest
            {
                UserId = userId,
                CategoryId = categoryId,
                CreatedAt = DateTime.UtcNow,
            }).ToList();

            _dbContext.UserInterests.AddRange(newInterests);
            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("Updated {Count} interests for user {UserId}", newInterests.Count, userId);
        }
    }
}
