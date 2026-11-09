using System.Reflection;

namespace Monogame.Enchanted.Debug.Inspection;

/// <summary>
/// Метаданные свойства для кэширования информации о свойстве
/// </summary>
internal class PropertyMetadata
{
    /// <summary>
    /// Информация о свойстве
    /// </summary>
    public PropertyInfo Property { get; }

    /// <summary>
    /// Имя для отображения
    /// </summary>
    public string DisplayName => Property.Name;

    private readonly IPropertyDrawer _drawer;

    public PropertyMetadata(PropertyInfo property)
    {
        Property = property;
        _drawer = PropertyDrawerRegistry.GetDrawer(property.PropertyType);
    }

    public void Draw(object obj)
    {
        _drawer.Draw(Property, obj);
    }
}
