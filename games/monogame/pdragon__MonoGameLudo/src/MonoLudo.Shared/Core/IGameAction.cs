namespace MonoLudo.Core
{
    public interface IGameAction
    {
        public void Start();
        public void Update();
        public void Complete();
        public bool IsCompleted { get; set; }
        //public event Action? OnComplete;
    }
}
