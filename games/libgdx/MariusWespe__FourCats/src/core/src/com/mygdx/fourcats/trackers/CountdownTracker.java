package com.mygdx.fourcats.trackers;

import com.mygdx.fourcats.Config;

public class CountdownTracker
{
    int tracker = 0;

    int remaining_seconds;

    public CountdownTracker()
    {
        remaining_seconds = Config.GAMELENGTH;
    }

    public void update()
    {
        tracker++;
        if (tracker == 60)
        {
            remaining_seconds--;
            tracker = 0;
        }
    }

    public int getCountdown()
    {
        return remaining_seconds;
    }
}
