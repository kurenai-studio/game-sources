using Microsoft.Xna.Framework;
using System;

namespace GraveDefensor.Windows.Actions
{
    public class ColorTransitionAction : Engine.Core.Action
    {
        public Color StartColor { get; set; }
        public Color EndColor { get; private set; }
        public Color Current { get; private set; }
        public ColorTransitionAction() { }
        public void Start(Color end, TimeSpan currentTime, TimeSpan duration)
        {
            EndColor = end;
            Start(currentTime, duration);
        }
        public void Start(Color start, Color end, TimeSpan currentTime, TimeSpan duration)
        {
            StartColor = start;
            EndColor = end;
            Start(currentTime, duration);
        }
        public override void Update(double percentage)
        {
            Current = Color.Lerp(StartColor, EndColor, (float)percentage);
            base.Update(percentage);
        }
        public ColorTransitionAction WithStartColor(Color start)
        {
            StartColor = Current = start;
            return this;
        }
    }
}
