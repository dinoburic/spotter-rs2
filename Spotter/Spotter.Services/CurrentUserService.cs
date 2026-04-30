using Microsoft.AspNetCore.Http;
using Spotter.Model.Exceptions;
using Spotter.Model.Static;
using System.Security.Claims;

namespace Spotter.Services
{
    public class CurrentUserService : ICurrentUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CurrentUserService(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public int GetUserId()
        {
            var claim = _httpContextAccessor.HttpContext?.User.Claims
                .FirstOrDefault(c => c.Type == "sub" || c.Type == ClaimTypes.NameIdentifier);

            if (claim == null || !int.TryParse(claim.Value, out var userId))
                throw new ClientException("Unauthorized.");

            return userId;
        }

        public string GetUsername()
        {
            var claim = _httpContextAccessor.HttpContext?.User.Claims
                .FirstOrDefault(c => c.Type == "unique_name" || c.Type == ClaimTypes.Name);

            return claim?.Value ?? string.Empty;
        }

        public string GetRole()
        {
            var claim = _httpContextAccessor.HttpContext?.User.Claims
                .FirstOrDefault(c => c.Type == "role" || c.Type == ClaimTypes.Role);

            return claim?.Value ?? string.Empty;
        }

        public bool IsAdmin()
        {
            return GetRole() == Roles.Admin;
        }
    }
}
