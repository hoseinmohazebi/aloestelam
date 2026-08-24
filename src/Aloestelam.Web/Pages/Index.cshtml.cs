using Aloestelam.Application.Abstractions;
using Aloestelam.Domain.Entities;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Aloestelam.Web.Pages;

public class IndexModel(ISiteInfoService siteInfoService) : PageModel
{
    public SiteInfo Site { get; private set; } = null!;

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        Site = await siteInfoService.GetAsync(cancellationToken);
    }
}
