namespace TowerProtect.App.Scopes;

public interface IServiceLocator
{
    T? Locate<T>() where T : notnull;
    T LocateRequired<T> () where T : notnull;
}
