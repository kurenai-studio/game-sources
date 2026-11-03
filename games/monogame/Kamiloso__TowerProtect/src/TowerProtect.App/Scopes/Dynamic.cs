namespace TowerProtect.App.Scopes;

public class Dynamic<T>(IServiceLocator serviceLocator)
    where T : notnull
{
    public virtual T Current => serviceLocator.LocateRequired<T>();

    public virtual bool TryGet(out T obj)
    {
        obj = serviceLocator.Locate<T>()!;
        return obj is not null;
    }
}
