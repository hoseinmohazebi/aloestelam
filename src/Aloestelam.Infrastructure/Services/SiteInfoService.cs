using Aloestelam.Application.Abstractions;
using Aloestelam.Domain.Entities;

namespace Aloestelam.Infrastructure.Services;

public sealed class SiteInfoService : ISiteInfoService
{
    public Task<SiteInfo> GetAsync(CancellationToken cancellationToken = default)
    {
        var info = SiteInfo.Create("آلواستعلام", "سامانه استعلام آنلاین");
        return Task.FromResult(info);
    }
}
