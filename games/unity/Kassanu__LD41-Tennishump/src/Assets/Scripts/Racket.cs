using System;
using UnityEngine;

public class Racket : MonoBehaviour {

    [SerializeField] private float clipPlaneAdjust = 1f;
    [SerializeField] float XHitAngleDampener = 0.15f;
    [SerializeField] float YHitAngleDampener = 0.05f;

    private Vector3 spin = Vector3.zero;

    private void Start() {
        Cursor.visible = false;
    }

    private void Update() {
        Vector3 mousePosition = Input.mousePosition;        
        this.transform.position = Camera.main.ScreenToWorldPoint(new Vector3(mousePosition.x, mousePosition.y, Camera.main.nearClipPlane + clipPlaneAdjust));
    }

    public void OnChildCollisionEnter(Collision collision) {
        if (collision.gameObject.tag == "Ball") {
            Ball ball = collision.gameObject.GetComponent<Ball>();
            if (!ball.Active) {
                this.spin = new Vector3(this.XHitAngleDampener * ( collision.gameObject.transform.position.x - this.gameObject.transform.position.x ), this.YHitAngleDampener * ( collision.gameObject.transform.position.y - this.gameObject.transform.position.y ), 0);
                Rigidbody rb = collision.gameObject.GetComponent<Rigidbody>();
                Vector3 tempVect = new Vector3(this.spin.x, this.spin.y, collision.relativeVelocity.magnitude);
                rb.velocity = tempVect;
                ball.Active = true;
                rb.useGravity = true;
            }
        }
    }

}
