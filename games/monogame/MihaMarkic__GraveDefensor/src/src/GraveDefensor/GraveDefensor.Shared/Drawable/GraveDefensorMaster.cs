using Settings = GraveDefensor.Engine.Settings;
using GraveDefensor.Shared.Service.Abstract;
using Microsoft.Xna.Framework;
using GraveDefensor.Shared.Drawable.Scenes;

namespace GraveDefensor.Shared.Drawable
{
    public sealed class GraveDefensorMaster: Master
    {
        Settings.Size windowSize;
        public Matrix Transformation => CurrentScene.Transformation;
        public void Init(IInitContext context, Settings.Master settings, Settings.Size windowSize)
        {
            this.windowSize = windowSize;
            var scene = context.ObjectPool.GetObject<BattleScene>();
            var sceneSettings = settings.Battles[0];
            scene.Init(context, sceneSettings, settings.Enemies, settings.Weapons.FromNames(sceneSettings.WeaponNames), windowSize);
            CurrentScene = scene;
        }
        public override void InitContent(IInitContentContext context)
        {
            CurrentScene.InitContent(context);
            base.InitContent(context);
        }
    }
}
