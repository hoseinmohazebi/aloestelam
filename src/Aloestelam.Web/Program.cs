using Aloestelam.Application;
using Aloestelam.Infrastructure;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
});

builder.Services.AddApplication();
builder.Services.AddInfrastructure();
builder.Services.AddRazorPages();

var app = builder.Build();

app.UseForwardedHeaders();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseRouting();
app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages().WithStaticAssets();

app.Run();
