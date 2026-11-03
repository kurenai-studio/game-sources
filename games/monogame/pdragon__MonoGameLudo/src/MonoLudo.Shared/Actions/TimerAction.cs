using MonoLudo.Core;

namespace MonoLudo.Shared.Actions
{
    internal class TimerAction: IGameAction
    {
        public bool IsCompleted { get; set; }
        private double TimeLeft;

        public TimerAction(float seconds) {
            //OnComplete += Complete;
            TimeLeft = seconds;
        }

        public void Start()
        {

        }

        public void Update()
        {
            TimeLeft -= Config.DeltaTime;// Time.GetFrameTime();
            if(TimeLeft <= 0)
            {
                TimeLeft = 0;
                IsCompleted = true;
            }
        }

        public void Complete()
        {
            //Console.WriteLine("Timer estimate");
        }
    }
}
