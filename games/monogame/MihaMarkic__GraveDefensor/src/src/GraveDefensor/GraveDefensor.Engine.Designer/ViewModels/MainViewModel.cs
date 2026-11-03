using Autofac;
using GraveDefensor.Engine.Designer.Core;
using GraveDefensor.Engine.Designer.Services.Abstract;
using GraveDefensor.Engine.Settings;
using System;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Threading.Tasks;
using System.Xml.Serialization;

namespace GraveDefensor.Engine.Designer.ViewModels
{
    public sealed class MainViewModel : ViewModel
    {
        readonly IFileService fileService;
        public event EventHandler? ExitRequested;
        public RelayCommand ExitCommand { get; }
        public RelayCommandAsync ShowSettingsCommand { get; }
        public RelayCommand CreateNewGameSettingsCommand { get; }
        public RelayCommandAsync OpenGameSettingsCommand { get; }
        public ContentViewModel Content { get; private set; } = default!;
        public bool IsInitializing { get; private set; }
        public bool IsLoadingGameSettings { get; private set; }
        public bool IsBusy => IsInitializing || IsLoadingGameSettings;
        ILifetimeScope containerScope = default!;
        readonly SettingsViewModel settingsViewModel;
        Type? previousContentType;
        Master? masterSettings;
        public MainViewModel(SettingsViewModel settingsViewModel, IFileService fileService)
        {
            this.settingsViewModel = settingsViewModel;
            this.fileService = fileService;
            ShowSettingsCommand = new RelayCommandAsync(() => ShowContentForAsync<SettingsViewModel>(), () => !IsBusy);
            OpenGameSettingsCommand = new RelayCommandAsync(OpenGameSettingsAsync, () => !IsBusy && Content is HomeViewModel);
            CreateNewGameSettingsCommand = new RelayCommand(CreateNewGameSettings, () => !IsBusy);
            ExitCommand = new RelayCommand(Exit);
            var ignore = ShowContentForAsync<HomeViewModel>();
        }
        void OnExitRequested(EventArgs e) => ExitRequested?.Invoke(this, e);
        public async Task InitAsync(CancellationToken ct = default)
        {
            IsInitializing = true;
            try
            {
                await settingsViewModel.LoadConfigurationAsync();
            }
            finally
            {
                IsInitializing = false;
            }
        }
        public void Exit() => OnExitRequested(EventArgs.Empty);

        public Task ShowContentForAsync<T>(CancellationToken ct = default)
            where T : notnull, ContentViewModel
        {
            return ShowContentForAsync(typeof(T), ct);
        }
        public async Task ShowContentForAsync(Type contentType, CancellationToken ct = default)
        {
            if (Content != null)
            {
                bool canClose = await Content.CanCloseAsync(ct);
                if (!canClose)
                {
                    return;
                }
                await Content.CloseAsync();
                Content.CloseRequested -= Content_CloseRequested;
                previousContentType = Content.GetType();
            }
            containerScope?.Dispose();
            containerScope = IoC.BeginLifetimeScope();
            var settings = (ContentViewModel)containerScope.Resolve(contentType);
            Content = settings;
            Content.CloseRequested += Content_CloseRequested;
            await Content.InitAsync(ct);
        }
        protected override void OnPropertyChanged(string name)
        {
            switch (name)
            {
                case nameof(IsBusy):
                case nameof(Content):
                    ShowSettingsCommand.RaiseCanExecuteChanged();
                    OpenGameSettingsCommand.RaiseCanExecuteChanged();
                    CreateNewGameSettingsCommand.RaiseCanExecuteChanged();
                    break;
            }
            base.OnPropertyChanged(name);
        }
        async void Content_CloseRequested(object? sender, EventArgs e)
        {
            if (previousContentType != null)
            {
                await ShowContentForAsync(previousContentType);
            }
        }

        async Task OpenGameSettingsAsync()
        {
            IsLoadingGameSettings = true;
            try
            {
                string path = "";
                masterSettings = await fileService.LoadGameSettingsAsync(path);
                AssignGameSettings();
            }
            finally
            {
                IsLoadingGameSettings = false;
            }
        }

        void CreateNewGameSettings()
        {
            masterSettings = new Master();
            AssignGameSettings();
        }

        void AssignGameSettings()
        {
            if (masterSettings != null && Content is HomeViewModel homeViewModel)
            {
                homeViewModel.AssignSettings(masterSettings);
            }
        }
    }
}
