using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection.Drawers;

/// <summary>
/// Драйвер для отображения свойств типа Vector3
/// </summary>
internal class Vector3PropertyDrawer : IPropertyDrawer
{
    public bool SupportsType(Type type) => type == typeof(global::System.Numerics.Vector3);

    public void Draw(PropertyInfo propertyInfo, object obj)
    {
        var value = propertyInfo.GetValue(obj);
        var vec3 = (global::System.Numerics.Vector3)value!;
        var x = vec3.X;
        var y = vec3.Y;
        var z = vec3.Z;
        
        ImGui.Text($"{propertyInfo.PropertyType.Name} (X, Y, Z)");
        ImGui.SameLine();
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().X / 3);
        
        bool changedX = ImGui.InputFloat("##x", ref x);
        ImGui.SameLine();
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().X / 3);
        bool changedY = ImGui.InputFloat("##y", ref y);
        ImGui.SameLine();
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail().X);
        bool changedZ = ImGui.InputFloat("##z", ref z);
        
        if (changedX || changedY || changedZ)
        {
            propertyInfo.SetValue(obj, new global::System.Numerics.Vector3(x, y, z));
        }
    }
}
