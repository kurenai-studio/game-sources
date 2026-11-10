using System;
using System.Collections.Generic;

public class MessageQueue
{
    private readonly Dictionary<Type, List<Delegate>> _listeners;

    private static MessageQueue _instance;

    public static MessageQueue Instance => _instance ??= new MessageQueue();

    private MessageQueue()
    {
        _listeners = new Dictionary<Type, List<Delegate>>();
    }

    public void AddListener<T>(Action<T> listener)
    {
        List<Delegate> listeners = null;
        if (_listeners.TryGetValue(typeof(T), out listeners))
        {
            listeners.Add(listener);
        }
        else
        {
            listeners = new List<Delegate> { listener };
            _listeners.Add(typeof(T), listeners);
        }
    }

    public void RemoveListener<T>(Action<T> listener)
    {
        List<Delegate> listeners = null;
        if (_listeners.TryGetValue(typeof(T), out listeners))
        {
            listeners.Remove(listener);
        }
    }

    public void SendMessage(IMessage message)
    {
        List<Delegate> listeners = null;
        if (_listeners.TryGetValue(message.GetType(), out listeners))
        {
            for (int i = 0; i < listeners.Count; i++)
            {
                listeners[i].DynamicInvoke(message);
            }
        }
    }
}