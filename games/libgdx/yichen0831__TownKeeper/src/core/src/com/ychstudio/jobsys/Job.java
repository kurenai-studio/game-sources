package com.ychstudio.jobsys;

import com.badlogic.gdx.math.Vector2;

public class Job {

    public enum Type {
        HUNTER,
        SWORDMAN,
        ARCHER
    }
    
    public Type type;
    public Vector2 location;
    long createdTime;
    long takenTime;
    boolean taken;
    
    public Job(Type type, Vector2 location) {
        this.type = type;
        this.location = location;
        createdTime = System.currentTimeMillis();
        taken = false;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((location == null) ? 0 : location.hashCode());
        result = prime * result + (int) (createdTime ^ (createdTime >>> 32));
        result = prime * result + ((type == null) ? 0 : type.hashCode());
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (!(obj instanceof Job))
            return false;
        Job other = (Job) obj;
        if (location == null) {
            if (other.location != null)
                return false;
        } else if (!location.equals(other.location))
            return false;
        if (createdTime != other.createdTime)
            return false;
        if (type != other.type)
            return false;
        return true;
    }
    
    
    
}
