using GraveDefensor.Engine.Settings;
using System;
using System.Collections.ObjectModel;
using System.Linq;

namespace GraveDefensor.Engine.Designer.ViewModels.Settings
{
    public class MasterSettingsViewModel: ViewModel
    {
        readonly Master source;
        public ObservableCollection<IEnemySettingsViewModel> Enemies { get; } = new ObservableCollection<IEnemySettingsViewModel>();
        public MasterSettingsViewModel(Master source)
        {
            this.source = source;
        }

        public void LoadEnemies()
        {
            var enemies = source.Enemies?.AllEnemies().ToArray() ?? new Enemy[0];
            foreach (var enemy in enemies)
            {
                IEnemySettingsViewModel item = enemy switch
                {
                    Skeleton s          => new SkeletonSettingsViewModel(s),
                    CreepyWorm cw       => new CreepyWormSettingsViewModel(cw),
                    _                   => throw new ArgumentException(message: $"Invalid enum value {enemy.GetType().Name}", paramName: nameof(enemy)),
                };
                Enemies.Add(item);
            }

        }
    }

    public class SkeletonSettingsViewModel: EnemySettingsViewModel<Skeleton>
    {
        public SkeletonSettingsViewModel(Skeleton source) : base(source)
        {
        }
    }
    public class CreepyWormSettingsViewModel: EnemySettingsViewModel<CreepyWorm>
    {
        public CreepyWormSettingsViewModel(CreepyWorm source) : base(source)
        {
        }
    }
    public interface IEnemySettingsViewModel
    {

    }
    public abstract class EnemySettingsViewModel<T>: ViewModel, IEnemySettingsViewModel
        where T: Enemy
    {
        readonly T source;
        public EnemySettingsViewModel(T source)
        {
            this.source = source;
        }
    }
}
