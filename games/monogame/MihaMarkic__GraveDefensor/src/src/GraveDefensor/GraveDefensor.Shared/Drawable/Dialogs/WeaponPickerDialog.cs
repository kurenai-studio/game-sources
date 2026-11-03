using Settings = GraveDefensor.Engine.Settings;
using Microsoft.Xna.Framework;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Drawable.Buttons;
using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using GraveDefensor.Shared.Drawable.Weapons;
using GraveDefensor.Shared.Messages;

namespace GraveDefensor.Shared.Drawable
{
    public class WeaponPickerDialog : Dialog
    {
        public const int HorizontalPadding = 5;
        public IWeaponPod Pod { get; private set; }
        Settings.Weapon[] weaponSettings;
        public WeaponPickerButton[] Buttons { get; private set; }
        IInitContext initContext;
        IInitContentContext initContentContext;

        public void Init(IInitContext initContext, IWeaponPod pod, Settings.Weapon[] weaponSettings)
        {
            const int width = 200;
            const int headerHeight = 30;
            this.initContext = initContext;
            Pod = pod;
            this.weaponSettings = weaponSettings;
            int height = MeasureContentHeight(weaponSettings.Length);
            Init(width, height, headerHeight: headerHeight, null);
        }

        public override void Position(Point topLeft)
        {
            base.Position(topLeft);
            Buttons = CreateButtons(initContext.ObjectPool, weaponSettings);
        }
        internal static int MeasureContentHeight(int numberOfButtons)
        {
            return 2 + (numberOfButtons-1) * HorizontalPadding + numberOfButtons * WeaponPickerButton.Height;
        }
        internal WeaponPickerButton[] CreateButtons(IObjectPool pool, Settings.Weapon[] weaponSettings)
        {
            const int delta = 5;
            
            Point topLeftButton = new Point(TopLeft.X + HorizontalPadding, TopLeft.Y + 5 + HeaderHeight.Value);
            var buttons = new WeaponPickerButton[weaponSettings.Length];
            for (int i = 0; i < buttons.Length; i++)
            {
                buttons[i] = pool.GetObject<WeaponPickerButton>();
                buttons[i].Init(weaponSettings[i], topLeftButton, Width - 2 * HorizontalPadding);
                topLeftButton = new Point(topLeftButton.X, topLeftButton.Y + WeaponPickerButton.Height + delta);
            }
            return buttons;
        }
        public override void InitContent(IInitContentContext context)
        {
            initContentContext = context;
            foreach (var button in Buttons)
            {
                button.InitContent(context);
            }
            base.InitContent(context);
        }
        internal IWeapon CreateWeapon(Settings.Weapon weaponSettings)
        {
            var weapon = WeaponFactory.GetWeaponFromPool(initContext, weaponSettings, Pod.Center);
            weapon.InitContent(initContentContext);
            return weapon;
        }
        public override void Update(UpdateContext context, int currentAmount)
        {
            foreach (var button in Buttons)
            {
                button.Update(context, currentAmount);
                if (button.ClickState == ClickState.Clicked)
                {
                    var weaponSettings = button.WeaponSettings;
                    Pod.Weapon = CreateWeapon(weaponSettings);
                    initContext.Dispatcher.Dispatch(new ChangeStatusMessage(amount: -weaponSettings.Price, health: 0));
                    Close();
                }
            }
            base.Update(context, currentAmount);
        }
        internal override void DrawContent(IDrawContext context)
        {
            context.FillRectangle(new Rectangle(TopLeft, new Point(Width, HeaderHeight.Value)), new Color(Color.White, 0.2f));
            context.DrawString(GlobalContent.Default.CoordinatesFont, "Pick weapon", TopLeft.AsVector2(), Color.Black);
            foreach (var button in Buttons)
            {
                button.Draw(context);
            }
        }

        public override void ReleaseResources(IObjectPool objectPool)
        {
            objectPool.ReleaseObjects(Buttons);
            base.ReleaseResources(objectPool);
        }
    }
}
