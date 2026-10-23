package com.mygdx.fourcats.events;

import java.util.HashSet;

public class EventBroker
{
    public static EventBroker Instance = new EventBroker();

    public static EventBroker getInstance()
    {
        return Instance;
    }

    private EventBroker()
    {}

    public HashSet<IMouseSpawnEventListener> MouseSpawnListeners = new HashSet<>();

    public HashSet<IMouseCaughtEventListener> MouseCaughtListeners = new HashSet<>();


    public void transmitMouseSpawn(MouseSpawnEvent event)
    {
        for (IMouseSpawnEventListener listener : MouseSpawnListeners)
        {
            listener.handleEvent(event);
        }
    }

    public void transmitMouseCaught(MouseCaughtEvent event)
    {
        for (IMouseCaughtEventListener listener : MouseCaughtListeners)
        {
            listener.handleEvent(event);
        }
    }

    public void clearListeners()
    {
        MouseCaughtListeners.clear();
        MouseSpawnListeners.clear();
    }
}
