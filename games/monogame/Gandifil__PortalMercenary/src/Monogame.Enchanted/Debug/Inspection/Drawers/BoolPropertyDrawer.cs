using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection.Drawers;

/// <summary>
/// Драйвер для отображения свойств типа bool
/// </summary>
internal class BoolPropertyDrawer : IPropertyDrawer
{
    public bool SupportsType(Type type) => type == typeof(bool);

    public void Draw(PropertyInfo propertyInfo, object obj)
    {
        var value = propertyInfo.GetValue(obj);
        var boolValue = (bool)value!;
        if (ImGui.Checkbox(propertyInfo.PropertyType.Name, ref boolValue))
        {
            propertyInfo.SetValue(obj, boolValue);
        }
    }
}
