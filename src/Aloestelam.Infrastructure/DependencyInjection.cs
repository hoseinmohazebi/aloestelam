using Aloestelam.Application.Abstractions;
using Aloestelam.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Aloestelam.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        services.AddSingleton<ISiteInfoService, SiteInfoService>();
        return services;
    }
}