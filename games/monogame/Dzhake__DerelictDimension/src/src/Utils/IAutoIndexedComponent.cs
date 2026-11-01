using Box2D.NET;
using DerelictDimension.ECS.PhysicsModule.Components;
using System;
using System.Collections.Generic;
using System.Text;

namespace DerelictDimension.Utils;

public interface IAutoIndexedComponent<TComp, TValue> : IIndexedComponent<TValue> where TComp : struct, IIndexedComponent<TValue>
{
    /// <summary>
    /// DO NOT USE THIS!!!!! Use <see cref="IAutoIndexedComponentExt.SetIndexedValue"/> instead.
    /// </summary>
    /// <remarks>
    /// This method sets field of the component, but does NOT update the index. <see cref="IAutoIndexedComponentExt.SetIndexedValue"/> uses this method internally, but it also updates the index. If the index is not updated, that's a nearly guaranteed crash. This method is public because otherwise I couldn't call it in the extension, and apparently using "ref this" inside interface doesn't really work.
    /// </remarks>
    public abstract void SetIndexedValueDIRECTLY(TValue value);
}

public static class IAutoIndexedComponentExt
{
    public static void SetIndexedValue<TComp, TValue>(ref this TComp comp, in Entity entity, TValue id, in ComponentIndex<TComp, TValue> index) where TComp : struct, IAutoIndexedComponent<TComp, TValue> where TValue : struct
    {
        var oldId = comp.GetIndexedValue();
        comp.SetIndexedValueDIRECTLY(id);
        index.UpdateIndex(in entity, ref comp, oldId);
    }
}
