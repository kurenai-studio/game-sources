using System.Collections.ObjectModel;
using Monogame.Enchanted.Debug.Inspection.Drawers;

namespace Monogame.Enchanted.Debug.Inspection;

/// <summary>
/// Регистр драйверов свойств для выбора подходящего драйвера
/// </summary>
internal static class PropertyDrawerRegistry
{
    private static readonly List<IPropertyDrawer> _drawers = new();

    static PropertyDrawerRegistry()
    {
        RegisterDrawers();
    }

    private static void RegisterDrawers()
    {
        _drawers.Add(new IntPropertyDrawer());
        _drawers.Add(new FloatPropertyDrawer());
        _drawers.Add(new Vector2PropertyDrawer());
        _drawers.Add(new Vector3PropertyDrawer());
        _drawers.Add(new Vector4PropertyDrawer());
        _drawers.Add(new ColorPropertyDrawer());
        _drawers.Add(new StringPropertyDrawer());
        _drawers.Add(new BoolPropertyDrawer());
        _drawers.Add(new FallbackPropertyDrawer());
    }

    /// <summary>
    /// Возвращает подходящий драйвер для указанного типа
    /// </summary>
    public static IPropertyDrawer GetDrawer(Type type)
    {
        return _drawers.FirstOrDefault(d => d.SupportsType(type)) 
            ?? _drawers.Last(); // FallbackPropertyDrawer всегда подходит
    }

    /// <summary>
    /// Получить все зарегистрированные драйверы
    /// </summary>
    public static ReadOnlyCollection<IPropertyDrawer> GetAllDrawers() => _drawers.AsReadOnly();
}
