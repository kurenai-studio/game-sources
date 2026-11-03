using Avalonia.Controls;
using Avalonia.Controls.Templates;
using GraveDefensor.Engine.Designer.ViewModels;
using System;
using System.Collections.Immutable;

namespace GraveDefensor.Designer
{
    public class ViewLocator : IDataTemplate
    {
        public bool SupportsRecycling => false;
        ImmutableDictionary<string, Type?> cache = ImmutableDictionary<string, Type?>.Empty;
        public IControl Build(object data)
        {
            var name = data.GetType().Name!.Replace("ViewModel", "View");
            if (!cache.TryGetValue(name, out var type))
            {
                type = Type.GetType($"GraveDefensor.Designer.Views.{name}");
                cache = cache.Add(name, type);
            }

            if (type != null)
            {
                return (Control)Activator.CreateInstance(type)!;
            }
            else
            {
                return new TextBlock { Text = $"Not Found: {name}" };
            }
        }

        public bool Match(object data) => data is ViewModel;
    }
}
