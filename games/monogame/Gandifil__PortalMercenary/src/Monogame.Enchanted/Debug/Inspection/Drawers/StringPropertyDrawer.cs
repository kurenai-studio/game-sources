using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection.Drawers;

/// <summary>
/// Драйвер для отображения свойств типа string
/// </summary>
internal class StringPropertyDrawer : IPropertyDrawer
{
    public bool SupportsType(Type type) => type == typeof(string);

    public void Draw(PropertyInfo propertyInfo, object obj)
    {
        var value = propertyInfo.GetValue(obj);
        var stringValue = (string?)value;
        if (ImGui.InputText(propertyInfo.PropertyType.Name, ref stringValue, 1024))
        {
            propertyInfo.SetValue(obj, stringValue);
        }
    }
}
