package com.dev.cariri.hitball.utils;

/**
 * Created by Ronildo on 27/02/2018.
 */

public class Timer {
    public static float TimeScale = 1.0f;
    public static float DeltaTime = 0f;
    private float mTime, mEndTime;
    private boolean mPaused;

    public Timer()	{
        mTime = mEndTime = -1;
        mPaused = true;
    }

    public Timer(float endTime)	{
        mTime = 0;
        mEndTime = endTime;
        mPaused = true;
    }

    public Timer(float endTime, boolean paused)	{
        mTime = 0;
        mEndTime = endTime;
        mPaused = paused;
    }

    public boolean tick() {
        if(!mPaused) mTime += DeltaTime;
        return isComplete();
    }

    public boolean tickAndReset() {
        if(!mPaused) mTime += DeltaTime;
        if(isComplete()) {
            reset();
            return true;
        }
        return false;
    }

    public void pause() { mPaused = true; }
    public void start() { mPaused = false; }
    public void stop() { mTime = 0; mPaused = true; }
    public void reset() { mTime = 0; }
    public void setTickRate(float t) { mEndTime = t; }
    public boolean isComplete() { return mEndTime != -1 && mTime >= mEndTime; }
    public boolean isRunning() { return !mPaused; }
    public float getTime() { return mTime; }
}
