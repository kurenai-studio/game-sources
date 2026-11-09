using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection.Drawers;

/// <summary>
/// Драйвер для отображения свойств типа float
/// </summary>
internal class FloatPropertyDrawer : IPropertyDrawer
{
    public bool SupportsType(Type type) => type == typeof(float);

    public void Draw(PropertyInfo propertyInfo, object obj)
    {
        var value = propertyInfo.GetValue(obj);
        var floatValue = (float)value!;
        if (ImGui.InputFloat(propertyInfo.PropertyType.Name, ref floatValue))
        {
            propertyInfo.SetValue(obj, floatValue);
        }
    }
}
