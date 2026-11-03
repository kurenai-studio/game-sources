using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using NLog;
using System;
using System.Linq;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable
{
    public interface IEnemyWave: IDrawable
    {
        EnemyWaveStatus Status { get; }
        EnemySet[] Sets { get; }
    }
    public class EnemyWave: Drawable, IEnemyWave
    {
        static readonly ILogger logger = LogManager.GetCurrentClassLogger();
        IInitContext initContext;
        Settings.EnemyWave settings;
        public EnemySet[] Sets { get; private set; }
        public EnemyWaveStatus Status { get; private set; }
        public void Init(IInitContext context, Settings.EnemyWave settings, Settings.Enemies enemiesSettings, Settings.Path[] pathsSettings)
        {
            initContext = context;
            this.settings = settings;
            logger.Info($"Wave {settings.Id} init");
            //Relative = TimeSpan.FromMilliseconds(settings.StartTimeOffset);
            Sets = new EnemySet[settings.Sets.Length];
            for (int i = 0; i < settings.Sets.Length; i++)
            {
                var setting = settings.Sets[i];
                var set = context.ObjectPool.GetObject<EnemySet>();
                var enemySettings = enemiesSettings.GetEnemyById(setting.EnemyId);
                var pathSettings = pathsSettings.Single(p => string.Equals(p.Id, setting.PathId, StringComparison.Ordinal));
                set.Init(context, setting, enemySettings, pathSettings);
                Sets[i] = set;
            }
            Status = EnemyWaveStatus.Ready;
        }
        public override void InitContent(IInitContentContext context)
        {
            foreach (var enemySet in Sets)
            {
                enemySet.InitContent(context);
            }
            base.InitContent(context);
        }
        public override void Update(UpdateContext context)
        {
            foreach (var enemySet in Sets)
            {
                enemySet.Update(context);
            }
            base.Update(context);
        }
        public override void Draw(IDrawContext context)
        {
            foreach (var enemySet in Sets)
            {
                enemySet.Draw(context);
            }
            base.Draw(context);
        }
    }

    public enum EnemyWaveStatus
    {
        Ready,
        Spawning,
        WaitingForFinish,
        Done
    }
}
