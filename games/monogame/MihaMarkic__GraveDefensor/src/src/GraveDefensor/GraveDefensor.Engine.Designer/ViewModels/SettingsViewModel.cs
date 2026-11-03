using GraveDefensor.Engine.Designer.Core;
using GraveDefensor.Engine.Designer.Models;
using GraveDefensor.Engine.Designer.Services.Abstract;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace GraveDefensor.Engine.Designer.ViewModels
{
    public sealed class SettingsViewModel: ContentViewModel
    {
        readonly IFileService fileService;
        Configuration configuration = new Configuration();
        public RelayCommand CloseCommand { get; }
        public string? AssetsPath { get; set; }
        public  bool IsLoading { get; private set; }
        public SettingsViewModel(IFileService fileService)
        {
            this.fileService = fileService;
            CloseCommand = new RelayCommand(() => OnCloseRequested(EventArgs.Empty));
        }
        public async Task LoadConfigurationAsync(CancellationToken ct = default)
        {
            IsLoading = true;
            try
            {
                configuration = await fileService.LoadConfigurationAsync(ct);
                AssetsPath = configuration.AssetsPath;
            }
            finally
            {
                IsLoading = false;
            }
        }
        // TODO fix re-entrancy
        async Task SaveConfigurationAsync(CancellationToken ct = default)
        {
            configuration.AssetsPath = AssetsPath;
            await fileService.SaveConfigurationAsync(configuration, ct);
        }
        protected override void OnPropertyChanged(string name)
        {
            if (!IsLoading)
            {
                switch (name)
                {
                    case nameof(AssetsPath):
                        var ignore = SaveConfigurationAsync();
                        break;
                }
            }
            base.OnPropertyChanged(name);
        }
    }
}
