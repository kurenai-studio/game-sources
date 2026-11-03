using System;
using System.Collections.Generic;

namespace GraveDefensor.Engine.Services.Abstract
{
    public interface IObjectPool
    {
        T GetObject<T>() where T : new();
        void ReleaseObject<T>(T item);
        void ReleaseObjects<T>(IEnumerable<T> items);
    }
}
