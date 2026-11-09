using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection.Drawers;

/// <summary>
/// Драйвер для отображения свойств типа Color
/// </summary>
internal class ColorPropertyDrawer : IPropertyDrawer
{
    public bool SupportsType(Type type) => type == typeof(global::Microsoft.Xna.Framework.Color);

    public void Draw(PropertyInfo propertyInfo, object obj)
    {
        var value = propertyInfo.GetValue(obj);
        var color = (global::Microsoft.Xna.Framework.Color)value!;
        var colorVec = new global::System.Numerics.Vector4(color.R / 255f, color.G / 255f, color.B / 255f, color.A / 255f);
        
        if (ImGui.ColorEdit4(propertyInfo.PropertyType.Name, ref colorVec))
        {
            var newColor = new global::Microsoft.Xna.Framework.Color(
                (byte)(colorVec.X * 255),
                (byte)(colorVec.Y * 255),
                (byte)(colorVec.Z * 255),
                (byte)(colorVec.W * 255)
            );
            propertyInfo.SetValue(obj, newColor);
        }
    }
}
