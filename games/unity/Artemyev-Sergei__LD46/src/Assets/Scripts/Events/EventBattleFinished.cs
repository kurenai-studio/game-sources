using System.Collections.Generic;

public class EventBattleFinished
{
    private List<IEventBattleFinishedListener> listeners = new List<IEventBattleFinishedListener>();

    public void AddListener(IEventBattleFinishedListener listener)
    {
        this.listeners.Add(listener);
    }

    public void RemoveListener(IEventBattleFinishedListener listener)
    {
        this.listeners.Remove(listener);
    }

    public void Dispatch(bool isPlayerWin)
    {
        for (int i = 0; i < this.listeners.Count; ++i)
        {
            try
            {
                this.listeners[i].OnBattleFinished(isPlayerWin);
            }
            catch (System.Exception e)
            {
                UnityEngine.Debug.LogException(e);
            }
        }
    }
}
