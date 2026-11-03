using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using TowerProtect.App.Scopes;
using TowerProtect.Domain.Model.Scopes;
using TowerProtect.Registry;

namespace TowerProtect.Scopes;

internal static class ScopeRegistryExtensions
{
    public static void InitializeScopes(this IServiceCollection srv)
    {
        srv.AddSingleton<ScopeManager>();

        srv.ReassignSingleton<IScopeSwitcher, ScopeManager>();
        srv.ReassignSingleton<IScopeExchanger, ScopeManager>();
        srv.ReassignSingleton<IServiceLocator, ScopeManager>();

        srv.AddStartDataScoped();
    }

    private static void AddStartDataScoped(this IServiceCollection srv)
    {
        Add<StartData>();
        Add<StartLocalData>();
        Add<StartRemoteData>();
        Add<StartMenuData>();

        void Add<T>() where T : StartData
        {
            srv.AddScoped(sp =>
            {
                var scopeManager = sp.GetRequiredService<ScopeManager>();
                var scopeData = scopeManager.StartData;
                var scopeType = scopeData.Type;

                return scopeData as T
                    ?? throw new ScopeResolveException(typeof(T), scopeType);
            });
        }
    }

    public static void UseLocalScoped<I, TLocal>(this IServiceCollection srv)
        where I : class
        where TLocal : class, I
    {
        srv.AddDynamicScoped<I, TLocal, I, I>(0b100);
    }

    public static void UseRemoteScoped<I, TRemote>(this IServiceCollection srv)
        where I : class
        where TRemote : class, I
    {
        srv.AddDynamicScoped<I, I, TRemote, I>(0b010);
    }

    public static void UseMenuScoped<I, TMenu>(this IServiceCollection srv)
        where I : class
        where TMenu : class, I
    {
        srv.AddDynamicScoped<I, I, I, TMenu>(0b001);
    }

    public static void UseGameplayScoped<I, TGameplay>(this IServiceCollection srv)
        where I : class
        where TGameplay : class, I
    {
        srv.AddDynamicScoped<I, TGameplay, TGameplay, I>(0b110);
    }

    public static void UseGameplayScoped<I, TLocal, TRemote>(this IServiceCollection srv)
        where I : class
        where TLocal : class, I
        where TRemote : class, I
    {
        srv.AddDynamicScoped<I, TLocal, TRemote, I>(0b110);
    }

    public static void UseFullScoped<I, TFull>(this IServiceCollection srv)
        where I : class
        where TFull : class, I
    {
        srv.AddDynamicScoped<I, TFull, TFull, TFull>(0b111);
    }

    public static void UseFullScoped<I, TGameplay, TMenu>(this IServiceCollection srv)
        where I : class
        where TGameplay : class, I
        where TMenu : class, I
    {
        srv.AddDynamicScoped<I, TGameplay, TGameplay, TMenu>(0b111);
    }

    public static void UseFullScoped<I, TLocal, TRemote, TMenu>(this IServiceCollection srv)
        where I : class
        where TLocal : class, I
        where TRemote : class, I
        where TMenu : class, I
    {
        srv.AddDynamicScoped<I, TLocal, TRemote, TMenu>(0b111);
    }

    private static void AddDynamicScoped<I, TLocal, TRemote, TMenu>(this IServiceCollection srv, int flags)
        where I : class
        where TLocal : class, I
        where TRemote : class, I
        where TMenu : class, I
    {
        bool localExists, remoteExists, menuExists;

        if (localExists = (flags & 0b100) != 0)
            srv.TryAddScoped<TLocal>();

        if (remoteExists = (flags & 0b010) != 0)
            srv.TryAddScoped<TRemote>();

        if (menuExists = (flags & 0b001) != 0)
            srv.TryAddScoped<TMenu>();

        srv.AddSingleton<Dynamic<I>>();
        srv.AddScoped<I>(sp =>
        {
            var startData = sp.GetRequiredService<StartData>();
            var scopeType = startData.Type;

            return scopeType switch
            {
                ScopeType.Local when localExists => sp.GetRequiredService<TLocal>(),
                ScopeType.Remote when remoteExists => sp.GetRequiredService<TRemote>(),
                ScopeType.Menu when menuExists => sp.GetRequiredService<TMenu>(),
                _ => throw new ScopeResolveException(typeof(I), scopeType)
            };
        });
    }
}
