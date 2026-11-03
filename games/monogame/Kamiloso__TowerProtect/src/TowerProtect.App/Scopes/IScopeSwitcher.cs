using System;
using TowerProtect.Domain.Model.Scopes;

namespace TowerProtect.App.Scopes;

public interface IScopeSwitcher
{
    void SwitchScope<T>(T startData) where T : StartData;

    void CrashToMenu(Exception ex)
    {
        Console.Error.WriteLine(ex);
        SwitchScope(new StartMenuData());
    }

    void CrashToMenu(string errorMessage)
    {
        Console.Error.WriteLine(errorMessage);
        SwitchScope(new StartMenuData());
    }
}
