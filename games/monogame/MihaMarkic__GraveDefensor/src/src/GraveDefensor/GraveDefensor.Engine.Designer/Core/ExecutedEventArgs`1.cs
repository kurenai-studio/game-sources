using System;

namespace GraveDefensor.Engine.Designer.Core
{
    public class ExecutedEventArgs<T> : EventArgs
    {
        public T Parameter { get; }
        public ExecutedEventArgs(T parameter)
        {
            Parameter = parameter;
        }
    }
}
