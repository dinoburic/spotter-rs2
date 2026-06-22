using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class SystemSettingService : ISystemSettingService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ILogger<SystemSettingService> _logger;

        public SystemSettingService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ILogger<SystemSettingService> logger)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<List<SystemSettingResponse>> GetAllAsync()
        {
            var settings = await _dbContext.SystemSettings
                .OrderBy(s => s.Key)
                .ToListAsync();

            return settings.Select(s => _mapper.Map<SystemSettingResponse>(s)).ToList();
        }

        public async Task<SystemSettingResponse> UpdateAsync(string key, SystemSettingUpdateRequest request)
        {
            _logger.LogInformation("Updating system setting {Key}", key);

            var setting = await _dbContext.SystemSettings.FirstOrDefaultAsync(s => s.Key == key);
            if (setting == null)
                throw new NotFoundException($"System setting with key '{key}' not found.");

            setting.Value = request.Value;
            setting.UpdatedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("System setting {Key} updated to {Value}", key, request.Value);
            return _mapper.Map<SystemSettingResponse>(setting);
        }
    }
}
