package com.justy41.handdrawn.components;

public class Player extends Component {
    public float speed;
    public float jumpForce;
    public float gravity;

    public Player(float speed, float jumpForce) {
        this.speed = speed;
        this.jumpForce = jumpForce;
        gravity = 0;
    }
}
