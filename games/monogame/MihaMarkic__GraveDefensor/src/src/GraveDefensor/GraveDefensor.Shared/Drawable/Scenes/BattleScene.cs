using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Shared.Messages;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using NLog;
using Righthand.MessageBus;
using System;
using System.Diagnostics;
using System.Linq;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Scenes
{
    public class BattleScene: ScrollableScene
    {
        static readonly ILogger logger = LogManager.GetCurrentClassLogger();
        public WeaponPod[] WeaponPods { get; private set; }
        public EnemyWave[] Waves { get; private set; }
        int currentWaveIndex = 0;
        public EnemyWave CurrentWave => Waves[currentWaveIndex];
        Settings.Battle settings;
        Settings.Weapon[] weaponsSettings;
        public int Health { get; private set; }
        public int Amount { get; private set; }
        public bool IsScrolling { get; private set; }
        public WeaponPickerDialog WeaponPickerDialog { get; private set; }
        Texture2D background;
        Subscription changeStatusSubscription;
        /// <summary>
        /// Is in scrolling mode, when user drags it horizontally
        /// </summary>
        IInitContext initContext;
        IInitContentContext initContentContext;
        public Dialog ActiveDialog => WeaponPickerDialog;
        public BattleSceneStatus Status { get; private set; }
        // battle ready state
        int batleReadyLoop;
        public void Init(IInitContext context, Settings.Battle settings, Settings.Enemies enemiesSettings, Settings.Weapon[] weaponsSettings, Settings.Size windowSize)
        {
            base.Init(new Point(windowSize.Width, windowSize.Height));
            initContext = context;
            this.settings = settings;
            this.weaponsSettings = weaponsSettings;
            Health = settings.Health;
            Amount = settings.Amount;
            WeaponPods = new WeaponPod[settings.WeaponPlaces.Length];
            for (int i = 0; i < settings.WeaponPlaces.Length; i++)
            {
                var setting = settings.WeaponPlaces[i];
                var wp = context.ObjectPool.GetObject<WeaponPod>();
                wp.Init(setting);
                WeaponPods[i] = wp;
            }
            Waves = new EnemyWave[settings.Waves.Length];
            for (int i=0; i<settings.Waves.Length; i++)
            {
                var setting = settings.Waves[i];
                var wave = context.ObjectPool.GetObject<EnemyWave>();
                wave.Init(context, setting, enemiesSettings, settings.Paths);
                Waves[i] = wave;
            }
            changeStatusSubscription = context.Dispatcher.Subscribe<ChangeStatusMessage>(OnChangeStatus);
            Status = BattleSceneStatus.Active;
        }
        /// <summary>
        /// Scrolling is disabled for when showing a dialog or when status is ready which
        /// displays the entire field.
        /// </summary>
        /// <returns></returns>
        protected override bool CanScroll() => ActiveDialog is null && Status != BattleSceneStatus.Ready;
        internal void OnChangeStatus(object key, ChangeStatusMessage message)
        {
            Health += message.Health;
            Amount += message.Amount;
        }
        public override void InitContent(IInitContentContext context)
        {
            initContentContext = context;
            foreach (var wp in WeaponPods)
            {
                wp.InitContent(context);
            }
            foreach (var wave in Waves)
            {
                wave.InitContent(context);
            }
            background = context.Load<Texture2D>(Assets.Scenes.GetAbsolute(settings.Background));
            Size = background.Bounds.Size;
            float scale = (float)WindowSize.Y / background.Bounds.Size.Y;
            Scale = new Vector2(scale, scale);
            Transformation = Matrix.CreateScale(scale);
            base.InitContent(context);
        }
        /// <summary>
        /// Click on entity is allowed only when not scrolling and dialog is absent
        /// </summary>
        internal bool CanEntityClick => !IsScrolling && WeaponPickerDialog == null;
        public override void Update(UpdateContext context)
        {
            switch (Status)
            {
                case BattleSceneStatus.Ready:
                    break;
                case BattleSceneStatus.Active:
                    var childContext = OffsetUpdateContext(context);
                    var clickedWeaponPod = UpdateWeaponPods(childContext, WeaponPods, CurrentWave, CanEntityClick);
                    if (clickedWeaponPod != null)
                    {
                        WeaponPickerDialog = CreateWeaponPickerDialog(childContext.ObjectPool, clickedWeaponPod);
                    }
                    var updateEnemyWavesResult = UpdateEnemyWaves(childContext, currentWaveIndex, CurrentWave, Waves);
                    if (updateEnemyWavesResult.NewStatus.HasValue)
                    {
                        Status = updateEnemyWavesResult.NewStatus.Value;
                    }
                    if (updateEnemyWavesResult.IsNextWave)
                    {
                        Debug.Assert(currentWaveIndex < Waves.Length - 1);
                        currentWaveIndex++;
                    }
                    bool resetWeaponPickerDialog = UpdateActiveDialog(context, childContext, Amount, ActiveDialog);
                    if (resetWeaponPickerDialog)
                    {
                        WeaponPickerDialog = null;
                    }
                    break;
                case BattleSceneStatus.Finishing:
                    Status = BattleSceneStatus.Finished;
                    break;
            }
            base.Update(context);
        }
        /// <summary>
        /// Updates weapon pods and returns a clicked weapon pod if any.
        /// Caller is responsible for process click - i.e. create <see cref="WeaponPickerDialog"/>.
        /// </summary>
        /// <param name="childContext"></param>
        /// <param name="weaponPods"></param>
        /// <param name="currentEnemyWave"></param>
        /// <param name="canEntityClick"></param>
        /// <returns></returns>
        public static IWeaponPod UpdateWeaponPods(UpdateContext childContext, IWeaponPod[] weaponPods, IEnemyWave currentEnemyWave, bool canEntityClick)
        {
            IWeaponPod clickedWeaponPod = null;
            // converts mouse coordinates to absolute to scene
            foreach (var wp in weaponPods)
            {
                wp.Update(childContext, currentEnemyWave);
                // disable upgrades for now
                if (canEntityClick && wp.ClickState == ClickState.Clicked && wp.Weapon is null)
                {
                    logger.Info($"Weapon pod {Array.IndexOf(weaponPods, wp)} was clicked");
                    clickedWeaponPod = wp;
                }
            }
            return clickedWeaponPod;
        }
        public static (BattleSceneStatus? NewStatus, bool IsNextWave) UpdateEnemyWaves(
            UpdateContext childContext, int currentWaveIndex, IEnemyWave currentEnemyWave, IEnemyWave[] enemyWaves)
        {
            var result = (NewStatus: (BattleSceneStatus?)null, IsNextWave: false);
            foreach (var wave in enemyWaves)
            {
                wave.Update(childContext);
            }
            if (currentEnemyWave.Status == EnemyWaveStatus.Done)
            {
                if (currentWaveIndex < enemyWaves.Length - 1)
                {
                    result.IsNextWave = true;
                }
                else
                {
                    result.NewStatus = BattleSceneStatus.Finishing;
                }
            }
            return result;
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="context"></param>
        /// <param name="childContext"></param>
        /// <param name="weaponPods"></param>
        /// <param name="currentWaveIndex"></param>
        /// <param name="currentEnemyWave"></param>
        /// <param name="enemyWaves"></param>
        /// <param name="canEntityClick"></param>
        /// <param name="amount"></param>
        /// <param name="activeDialog"></param>
        /// <returns>True when <see cref="WeaponPickerDialog"/> has to be set to null, false otherwise.</returns>
        public static bool UpdateActiveDialog(UpdateContext context, UpdateContext childContext, int amount, Dialog activeDialog)
        {
            bool resetWeaponPickerDialog = false;
            if (activeDialog != null)
            {
                activeDialog.Update(childContext, amount);
                if (activeDialog.State == DialogState.Closing)
                {
                    context.ObjectPool.ReleaseObject(activeDialog);
                    resetWeaponPickerDialog = true;
                }
            }
            return resetWeaponPickerDialog;
        }
        internal WeaponPickerDialog CreateWeaponPickerDialog(IObjectPool pool, IWeaponPod pod)
        {
            Debug.Assert(ActiveDialog is null);
            var dialog = pool.GetObject<WeaponPickerDialog>();
            dialog.Init(initContext, pod, weaponsSettings);
            dialog.Position(GetDialogTopLeft(pod.Bounds, View, dialog.Size));
            dialog.InitContent(initContentContext);
            return dialog;
        }
        internal static Point GetDialogTopLeft(Rectangle entityBounds, Rectangle view, Point dialogSize)
        {
            var result = new Point();
            if (entityBounds.Right + dialogSize.X > view.Width)
            {
                result.X = entityBounds.Left - dialogSize.X;
            }
            else
            {
                result.X = entityBounds.Right;
            }
            if (entityBounds.Bottom + dialogSize.Y > view.Height)
            {
                result.Y = entityBounds.Top - dialogSize.Y;
            }
            else
            {
                result.Y = entityBounds.Top;
            }
            return result;
        }
        public override void Draw(IDrawContext context)
        {
            context.Draw(background, Vector2.Zero, Color.White);
            foreach (var wp in WeaponPods)
            {
                wp.Draw(context);
            }
            foreach (var wave in Waves)
            {
                wave.Draw(context);
            }
            if (Globals.ShowPaths)
            {
                foreach (var path in settings.Paths)
                {
                    DrawPath(context, path);
                }
            }
            DrawHeader(context);
            ActiveDialog?.Draw(context);
            base.Draw(context);
        }
        void DrawHeader(IDrawContext context)
        {
            const int HeaderHeight = 60;
            const float BetweenColumns = 80;
            const float BetweenRows = 20;
            const float Top = 10;
            const float Left = 10;
            var view = View;
            var topLeftView = new Vector2(view.Left, view.Top);
            context.FillRectangle(new Rectangle(view.Left, view.Top, view.Width, HeaderHeight), new Color(Color.Black, 0.2f));
            context.DrawString(GlobalContent.Default.HudFont, "Health", topLeftView + new Vector2(Left, Top), Color.Yellow);
            context.DrawString(GlobalContent.Default.HudFont, Health.ToString("#,##0"), topLeftView + new Vector2(Left, Top + BetweenRows), Color.Yellow);
            context.DrawString(GlobalContent.Default.HudFont, "Amount", topLeftView + new Vector2(Left + BetweenColumns, Top), Color.Yellow);
            context.DrawString(GlobalContent.Default.HudFont, Amount.ToString("#,##0"), topLeftView + new Vector2(Left + BetweenColumns, Top + BetweenRows), Color.Yellow);

        }
        void DrawPath(IDrawContext context, Settings.Path path)
        {
            for (int i = 1; i < path.Points.Length; i++)
            {
                var prev = path.Points[i - 1];
                var next = path.Points[i];
                context.DrawLine(prev.X, prev.Y, next.X, next.Y, Color.Yellow, 3f);
            }
        }

        public override void ReleaseResources(IObjectPool objectPool)
        {
            objectPool.ReleaseObjects(WeaponPods);
            objectPool.ReleaseObject(WeaponPickerDialog);
            changeStatusSubscription.Dispose();
            base.ReleaseResources(objectPool);
        }
    }

    public enum BattleSceneStatus
    {
        Ready,
        Active,
        /// <summary>
        /// Transition to <see cref="Finish"/>.
        /// </summary>
        Finishing,
        Finished
    }
}
