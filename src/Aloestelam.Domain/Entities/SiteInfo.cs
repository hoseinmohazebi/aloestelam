using Aloestelam.Domain.Common;

namespace Aloestelam.Domain.Entities;

public class SiteInfo : Entity
{
    public string Name { get; private set; } = string.Empty;
    public string Tagline { get; private set; } = string.Empty;

    private SiteInfo()
    {
    }

    public static SiteInfo Create(string name, string tagline)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);
        ArgumentException.ThrowIfNullOrWhiteSpace(tagline);

        return new SiteInfo
        {
            Name = name.Trim(),
            Tagline = tagline.Trim()
        };
    }
}
