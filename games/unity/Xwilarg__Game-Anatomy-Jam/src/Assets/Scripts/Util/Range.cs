using System;

namespace AnatomyJam.Util
{
    [Serializable]
    public struct Range<T>
    {
        public T Min;
        public T Max;
    }
}
