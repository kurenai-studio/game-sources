/// <summary>
/// An abstract base class for all edit operations made via the bus line editor tool.
/// </summary>
public abstract partial class AbstractEdit
{
    /// <summary>
    /// Gets the name of the edit operation.
    /// </summary>
    /// <remarks>
    /// This property is used for debugging purposes and is not intended to be modified by the user.
    /// Name is derived from the class name of the implementing class at runtime. 
    /// For example, if a class named "BusStopEdit" implements AbstractEdit, the Name property will return "BusStopEdit".
    /// </remarks>
    private string Name { 
        get{
            return GetType().Name;
        } 
    }
    /// <summary>
    /// Reverts the last player action in the undo history.
    /// </summary>
    public abstract void Revert();
    /// <summary>
    /// Called when the edit is dropped from the history without being reverted,
    /// so it can free any nodes it kept alive for undo.
    /// </summary>
    public virtual void OnDiscarded() { }
    /// <summary>
    /// Applies the player action asociated with the instance.
    /// </summary>
    /// <remarks>
    /// This method is called when the player wants to redo an action that was previously undone.
    /// Applies the last player undo in the redo history
    /// </remarks>
    public abstract void Apply();
     
}
