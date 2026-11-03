using Microsoft.Extensions.DependencyInjection;
using System;
using TowerProtect.App.Scopes;
using TowerProtect.Domain.Model.Scopes;

namespace TowerProtect.Scopes;

internal sealed class ScopeManager(IServiceProvider serviceProvider)
    : IScopeSwitcher, IScopeExchanger, IServiceLocator, IDisposable
{
    public StartData StartData { get; private set; } = new StartMenuData();

    private IServiceScope _currentScope = serviceProvider.CreateScope();
    private StartData? _nextStartData; // not null -> delayed

    public void SwitchScope<T>(T startData) where T : StartData
    {
        _nextStartData = startData;
    }

    public bool ExchangeScopeIfDelayed()
    {
        if (_nextStartData is null)
            return false;

        _currentScope.Dispose();

        StartData = _nextStartData;
        _nextStartData = null;

        _currentScope = serviceProvider.CreateScope();

        return true;
    }

    public T? Locate<T>() where T : notnull
        => _currentScope.ServiceProvider.GetService<T>();

    public T LocateRequired<T>() where T : notnull
        => _currentScope.ServiceProvider.GetRequiredService<T>();

    public void Dispose() => _currentScope.Dispose();
}
