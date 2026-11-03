using AutoMapper;
using GraveDefensor.Engine.Designer.Models;
using GraveDefensor.Engine.Designer.ViewModels;

namespace GraveDefensor.Engine.Designer
{
    public static class Globals
    {
        public static MapperConfiguration MapperConfiguration { get; private set; } = default!;
        static Globals()
        {
            InitAutoMapper();
        }
        public static void InitAutoMapper()
        {
            MapperConfiguration = new MapperConfiguration(cfg => cfg.CreateMap<Configuration, SettingsViewModel>());
        }
    }
}
