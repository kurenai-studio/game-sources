using System.Collections.Generic;

public class EventSquadDefeated
{
    private List<IEventSquadDefeatedListener> listeners = new List<IEventSquadDefeatedListener>();

    public void AddListener(IEventSquadDefeatedListener listener)
    {
        this.listeners.Add(listener);
    }

    public void RemoveListener(IEventSquadDefeatedListener listener)
    {
        this.listeners.Remove(listener);
    }

    public void Dispatch(Squad defeatedSquad)
    {
        for (int i = 0; i < this.listeners.Count; ++i)
        {
            try
            {
                this.listeners[i].OnSquadDefeated(defeatedSquad);
            }
            catch (System.Exception e)
            {
                UnityEngine.Debug.LogException(e);
            }
        }
    }
}
