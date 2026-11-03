using Avalonia;
using Avalonia.Controls;
using Avalonia.Markup.Xaml;
using GraveDefensor.Engine.Designer.ViewModels;
using System;

namespace GraveDefensor.Designer
{
    public class MainWindow : Window
    {
        public MainWindow(MainViewModel viewModel)
        {
            InitializeComponent();
            DataContext = viewModel;
#if DEBUG
            this.AttachDevTools();
#endif
            viewModel.ExitRequested += ViewModel_ExitRequested;
        }

        void ViewModel_ExitRequested(object? sender, EventArgs e)
        {
            Close();
        }

        private void InitializeComponent()
        {
            AvaloniaXamlLoader.Load(this);
        }
    }
}