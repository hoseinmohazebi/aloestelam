using Aloestelam.Domain.Entities;

namespace Aloestelam.Application.Abstractions;

public interface ISiteInfoService
{
    Task<SiteInfo> GetAsync(CancellationToken cancellationToken = default);
}
