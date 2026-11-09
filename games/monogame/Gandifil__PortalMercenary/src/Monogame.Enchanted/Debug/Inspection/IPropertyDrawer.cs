using System.Reflection;

namespace Monogame.Enchanted.Debug.Inspection;

/// <summary>
/// Интерфейс драйвера отображения свойства
/// </summary>
public interface IPropertyDrawer
{
    /// <summary>
    /// Проверяет, поддерживает ли драйвер указанный тип
    /// </summary>
    bool SupportsType(Type type);

    /// <summary>
    /// Рисует свойство в инспекторе
    /// </summary>
    void Draw(PropertyInfo propertyInfo, object obj);
}
