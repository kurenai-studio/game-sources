package com.ychstudio.ai;

import com.badlogic.gdx.math.Vector2;

public class Node {

    int gCost;
    int hCost;

    public Node prevNode;
    public Node nextNode;

    int x;
    int y;

    boolean closed;

    final Vector2 position;

    public Node(int x, int y) {
        this.x = x;
        this.y = y;

        gCost = 0;
        hCost = 0;

        prevNode = null;
        nextNode = null;

        closed = false;

        position = new Vector2(x + 0.5f, y + 0.5f);
    }

    public int fCost() {
        return gCost + hCost;
    }

    public Vector2 getPosition() {
        return position;
    }

}
