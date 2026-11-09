using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection.Drawers;

/// <summary>
/// Драйвер для отображения свойств типа Vector4
/// </summary>
internal class Vector4PropertyDrawer : IPropertyDrawer
{
    public bool SupportsType(Type type) => type == typeof(global::System.Numerics.Vector4);

    public void Draw(PropertyInfo propertyInfo, object obj)
    {
        var value = propertyInfo.GetValue(obj);
        var vec4 = (global::System.Numerics.Vector4)value!;
        var x = vec4.X;
        var y = vec4.Y;
        var z = vec4.Z;
        var w = vec4.W;
        
        ImGui.Text($"{propertyInfo.PropertyType.Name} (X, Y, Z, W)");
        ImGui.SameLine();
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().X / 4);
        
        bool changedX = ImGui.InputFloat("##x", ref x);
        ImGui.SameLine();
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().X / 4);
        bool changedY = ImGui.InputFloat("##y", ref y);
        ImGui.SameLine();
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().X / 4);
        bool changedZ = ImGui.InputFloat("##z", ref z);
        ImGui.SameLine();
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().X);
        bool changedW = ImGui.InputFloat("##w", ref w);
        
        if (changedX || changedY || changedZ || changedW)
        {
            propertyInfo.SetValue(obj, new global::System.Numerics.Vector4(x, y, z, w));
        }
    }
}
