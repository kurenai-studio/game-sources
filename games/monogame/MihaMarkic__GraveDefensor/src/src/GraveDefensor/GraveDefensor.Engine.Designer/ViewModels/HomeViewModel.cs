using GraveDefensor.Engine.Designer.ViewModels.Settings;

namespace GraveDefensor.Engine.Designer.ViewModels
{
    public class HomeViewModel: ContentViewModel
    {
        public MasterSettingsViewModel? Master { get; private set; }
        public void AssignSettings(Engine.Settings.Master source)
        {
            Master = new MasterSettingsViewModel(source);
        }
    }
}
