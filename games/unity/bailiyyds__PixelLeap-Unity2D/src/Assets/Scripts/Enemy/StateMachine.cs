namespace PixelLeap.Enemy
{
    /// <summary>有限状态机的状态基类。每个状态只关心"进入 / 每帧 / 退出"，切换逻辑集中在状态内部。</summary>
    public abstract class State
    {
        protected readonly EnemyBrain brain;
        public float Elapsed { get; private set; }
        protected State(EnemyBrain brain) { this.brain = brain; }

        public void EnterInternal() { Elapsed = 0f; Enter(); }
        public void TickInternal(float dt) { Elapsed += dt; Tick(dt); }

        protected virtual void Enter() { }
        protected virtual void Tick(float dt) { }
        public virtual void Exit() { }
        public virtual string Name => GetType().Name;
    }

    public class StateMachine
    {
        public State Current { get; private set; }
        public State Previous { get; private set; }

        public void Change(State next)
        {
            if (next == null || next == Current) return;
            Current?.Exit();
            Previous = Current;
            Current = next;
            Current.EnterInternal();
        }

        public void Tick(float dt) => Current?.TickInternal(dt);
    }
}
