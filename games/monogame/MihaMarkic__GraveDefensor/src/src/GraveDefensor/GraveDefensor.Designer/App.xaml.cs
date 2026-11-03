using Avalonia;
using Avalonia.Markup.Xaml;

namespace GraveDefensor.Designer
{
    public class App : Application
    {
        public override void Initialize()
        {
            AvaloniaXamlLoader.Load(this);
        }
   }
}