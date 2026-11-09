using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection.Drawers;

/// <summary>
/// Драйвер для отображения неподдерживаемых типов (fallback)
/// </summary>
internal class FallbackPropertyDrawer : IPropertyDrawer
{
    public bool SupportsType(Type type) => true;

    public void Draw(PropertyInfo propertyInfo, object obj)
    {
        var value = propertyInfo.GetValue(obj);
        ImGui.Text($"{propertyInfo.PropertyType.Name}: {value?.ToString() ?? "null"}");
    }
}
