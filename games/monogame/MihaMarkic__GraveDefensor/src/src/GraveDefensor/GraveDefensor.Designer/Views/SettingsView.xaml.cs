using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.VisualTree;
using GraveDefensor.Engine.Designer.ViewModels;

namespace GraveDefensor.Designer.Views
{
    public class SettingsView : ViewModelUserControl<SettingsViewModel>
    {
        public SettingsView() => InitializeComponent();

        void InitializeComponent() => AvaloniaXamlLoader.Load(this);

        async void OnAssetsShowDialog(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFolderDialog
            {
                DefaultDirectory = ViewModel.AssetsPath,
                
            };
            string directory = await dialog.ShowAsync((Window)Parent.GetVisualRoot());
            if (!string.IsNullOrWhiteSpace(directory))
            {
                ViewModel.AssetsPath = directory;
            }
        }
    }
}
