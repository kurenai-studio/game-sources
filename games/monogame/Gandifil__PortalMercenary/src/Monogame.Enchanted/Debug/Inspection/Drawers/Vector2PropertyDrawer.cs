using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection.Drawers;

/// <summary>
/// Драйвер для отображения свойств типа Vector2
/// </summary>
internal class Vector2PropertyDrawer : IPropertyDrawer
{
    public bool SupportsType(Type type) => type == typeof(global::System.Numerics.Vector2);

    public void Draw(PropertyInfo propertyInfo, object obj)
    {
        var value = propertyInfo.GetValue(obj);
        var vec2 = (global::System.Numerics.Vector2)value!;
        var x = vec2.X;
        var y = vec2.Y;
        
        ImGui.Text($"{propertyInfo.PropertyType.Name} (X, Y)");
        ImGui.SameLine();
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().X / 2);
        
        bool changedX = ImGui.InputFloat("##x", ref x);
        ImGui.SameLine();
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().X);
        bool changedY = ImGui.InputFloat("##y", ref y);
        
        if (changedX || changedY)
        {
            propertyInfo.SetValue(obj, new global::System.Numerics.Vector2(x, y));
        }
    }
}
