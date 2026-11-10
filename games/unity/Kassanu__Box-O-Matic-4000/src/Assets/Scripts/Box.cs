using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Box : MonoBehaviour {

    private bool isHeld = false;
    public bool IsHeld {
        get { return this.isHeld; }
        set {
            this.isHeld = value;
            this.rb2d.simulated = !value;
        }
    }
    private bool highlight = false;
    public bool Highlight {
        get { return this.highlight; }
        set {
            this.highlight = value;
            if (this.highlight) {
                GetComponent<Renderer>().material = this.highlightMaterial;
            } else {
                GetComponent<Renderer>().material = this.normalMaterial;
            }
        }
    }

    private bool onConveyor = true;
    public bool OnConveyor {
        get { return this.onConveyor; }
        set { this.onConveyor = value; }
    }


    [SerializeField]
    private Material normalMaterial;
    [SerializeField]
    private Material highlightMaterial;
    private Rigidbody2D rb2d;

    void Start() {
        this.rb2d = GetComponent<Rigidbody2D>();
        this.Highlight = false;
    }

    public float LeftOrRight(Vector2 A, Vector2 B) {
        return A.x * -B.y + A.y * B.x;
    }

    public void Throw(Vector2 throwForce, Vector2 velocity) {
        if (this.rb2d != null) {
            this.rb2d.velocity = velocity;
            this.rb2d.AddForce(throwForce, ForceMode2D.Impulse);
        }
    }

    public void Throw(Vector2 throwForce) {
        if (this.rb2d != null) {
            this.rb2d.AddForce(throwForce, ForceMode2D.Impulse);
        }
    }

    public Vector2 GetVelocity() {
        if (this.rb2d != null) {
            return this.rb2d.velocity;
        }

        return Vector2.zero;
    }
}
