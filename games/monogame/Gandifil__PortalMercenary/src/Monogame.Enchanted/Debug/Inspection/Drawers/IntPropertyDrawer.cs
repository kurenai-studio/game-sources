using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection.Drawers;

/// <summary>
/// Драйвер для отображения свойств типа int
/// </summary>
internal class IntPropertyDrawer : IPropertyDrawer
{
    public bool SupportsType(Type type) => type == typeof(int);

    public void Draw(PropertyInfo propertyInfo, object obj)
    {
        var value = propertyInfo.GetValue(obj);
        var intValue = (int)value!;
        if (ImGui.InputInt(propertyInfo.PropertyType.Name, ref intValue))
        {
            propertyInfo.SetValue(obj, intValue);
        }
    }
}
