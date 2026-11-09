using System.Collections.Concurrent;
using System.Reflection;
using ImGuiNET;

namespace Monogame.Enchanted.Debug.Inspection;

public class Inspector
{
    private static readonly HashSet<object> _inspectables = new ();
    private static readonly ConcurrentDictionary<Type, List<PropertyMetadata>> _typeCache = new();

    /// <summary>
    /// Добавляет объект для редактирования в инспекторе
    /// Performs reflection once and caches the property metadata
    /// </summary>
    public static void Add(object o)
    {
        lock (_inspectables)
        {
            if (!_inspectables.Contains(o))
            {
                var type = o.GetType();
                if (!_typeCache.TryGetValue(type, out _))
                {
                    _typeCache[type] = GetProperties(type);
                    Log.Info($"Inspected type {type}");
                }
                _inspectables.Add(o);
                Log.Info($"Inspected object {type} {o.GetHashCode()}");
            }
        }
    }

    private static List<PropertyMetadata> GetProperties(Type type)
    {
        const BindingFlags bindingFlags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance;
        var properties = new List<PropertyMetadata>();
        
        foreach (var prop in type.GetProperties(bindingFlags))
        {
            var propType = prop.PropertyType;
            var isComplexUserClass = propType.IsClass 
                                      && propType != typeof(string) 
                                      && !propType.Namespace.StartsWith("System");

            //if ()
            properties.Add(new PropertyMetadata(prop));
        }

        return properties;
    }

    public static void Draw()
    {
        ImGui.SetNextWindowSize(new global::System.Numerics.Vector2(200, 300), ImGuiCond.FirstUseEver);
        foreach (var data in _inspectables)
        {
            DrawObject(data);
        }
    }

    private static void DrawObject(object obj)
    {
        var strId = obj.GetHashCode().ToString();
        var type = obj.GetType();
        var typeName = type.Name;
        
        if (!ImGui.Begin($"Inspect {typeName} {strId}"))
            return;

        var metadata = _typeCache[type];
        foreach (var property in metadata)
        {
            //ImGui.PushID($"{strId}.{property.DisplayName}");
            property.Draw(obj);
            //ImGui.PopID();
        }

        ImGui.End();
    }
}
