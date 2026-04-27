using FluentValidation;
using Microsoft.EntityFrameworkCore;
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

        public UserService(SpotterDbContext dbContext, MapsterMapper.IMapper mapper, IValidator<UserInsertRequest> insertValidator, IValidator<UserUpdateRequest> updateValidator, ICryptoService cryptoService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _cryptoService = cryptoService;
        }

        protected override IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearch? search)
        {
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
            await _insertValidator.ValidateAndThrowAsync(request);

            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
                throw new ClientException($"Email '{request.Email}' is already in use.");

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username))
                throw new ClientException($"Username '{request.Username}' is already in use.");

            var entity = MapInsertRequestToEntity(request);
            entity.CreatedAt = DateTime.UtcNow;

            _dbContext.Users.Add(entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<UserResponse>(entity);
        }

        public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest request)
        {
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.Users.FindAsync(id);
            if (entity == null)
                throw new NotFoundException($"User with id {id} not found.");

            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email && u.Id != id))
                throw new ClientException($"Email '{request.Email}' is already in use.");

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username && u.Id != id))
                throw new ClientException($"Username '{request.Username}' is already in use.");

            MapUpdateRequestToEntity(request, entity);

            _dbContext.Users.Update(entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<UserResponse>(entity);
        }

        public override async Task DeleteAsync(int id)
        {
            var entity = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (entity == null)
                throw new NotFoundException($"User with id {id} not found.");

            _dbContext.Users.Remove(entity);
            await _dbContext.SaveChangesAsync();
        }

        public async Task<UserSensitveResponse?> GetByUsernameAsync(string username)
        {
            var user = await _dbContext.Users
                .AsNoTracking()
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username == username);

            if (user == null)
                return null;

            var response = _mapper.Map<UserSensitveResponse>(user);
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
    }
}
