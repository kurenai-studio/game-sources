using System.Collections.Generic;

public class EventSquadCapturedFlag
{
    private List<IEventSquadCapturedFlagListener> listeners = new List<IEventSquadCapturedFlagListener>();

    public void AddListener(IEventSquadCapturedFlagListener listener)
    {
        this.listeners.Add(listener);
    }

    public void RemoveListener(IEventSquadCapturedFlagListener listener)
    {
        this.listeners.Remove(listener);
    }

    public void Dispatch(Squad squad)
    {
        for (int i = 0; i < this.listeners.Count; ++i)
        {
            try
            {
                this.listeners[i].OnSquadCapturedFlag(squad);
            }
            catch (System.Exception e)
            {
                UnityEngine.Debug.LogException(e);
            }
        }
    }
}
