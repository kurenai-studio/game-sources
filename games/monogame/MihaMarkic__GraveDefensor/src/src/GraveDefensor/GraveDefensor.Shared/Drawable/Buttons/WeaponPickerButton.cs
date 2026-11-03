using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Buttons
{
    public class WeaponPickerButton : PickerButton
    {
        Texture2D image;
        public Settings.Weapon WeaponSettings { get; private set; }
        SpriteFont descriptionFont;

        public void Init(Settings.Weapon weaponSettings, Point topLeft, int width)
        {
            WeaponSettings = weaponSettings;
            Init(new Rectangle(topLeft, new Point(width, Height)));
        }
        public override void InitContent(IInitContentContext context)
        {
            image = context.Load<Texture2D>(Assets.Weapons.FromSettings(WeaponSettings));
            descriptionFont = context.Load<SpriteFont>(Assets.Fonts.WeaponDescriptionFont);
            base.InitContent(context);
        }
        public void Update(UpdateContext context, int currentAmount)
        {
            IsEnabled = currentAmount >= WeaponSettings.Price;
            base.Update(context);
        }

        public override void DrawContent(IDrawContext context)
        {
            const int padding = 2;
            const int distanceToImage = 10;
            const int lineHeight = 20;
            context.Draw(image, new Vector2(Bounds.Left, Bounds.Top), Color.White);
            int left = Bounds.Left + image.Width + distanceToImage;
            int top = Bounds.Top + padding;
            context.DrawString(descriptionFont, WeaponSettings.Name, new Vector2(left,top), Color.Black);
            top += lineHeight;
            context.DrawString(descriptionFont, $"{WeaponSettings.Price:#,##0}e", new Vector2(left, top), Color.Black);
            base.DrawContent(context);
        }
        public override void ReleaseResources(IObjectPool objectPool)
        {
            base.ReleaseResources(objectPool);
        }
    }
}
