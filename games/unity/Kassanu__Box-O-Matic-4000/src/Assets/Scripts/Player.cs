using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class Player : MonoBehaviour {

    public float maxSpeed = 10f;
    public float speed = 10f;
    public float jumpForce = 10f;
    public float pickUpRadius = 1f;

    public float throwForce = 0f;
    public float throwForceMax = 10f;
    public float throwForceVerticalAdjustment = 1f;
    public float throwForceStep = 1f;
    private bool boxJustPickedUp = false;
    public bool facingRight = false;
    public bool FacingRight {
        get { return this.facingRight; }
        set {
            this.facingRight = value;
            this.UpdateHoldPosition();
            this.FlipSprite();
        }
    }

    private bool alive = true;
    public bool Alive {
        get { return this.alive; }
        set { this.alive = value; }
    }

    private Rigidbody2D rb2d;
    [SerializeField]
    private float rayLength = 1f;

    public Box heldBox = null;
    private Box closestBox = null;

    [SerializeField]
    private Transform holdPoint;
    [SerializeField]
    private GameObject chargeBar;
    [SerializeField]
    private SpriteRenderer sprite;

    [SerializeField]
    private Vector3[] rayPositions;

    private string killedBy = "";
    public string KilledBy {
        get { return this.killedBy; }
        set { this.killedBy = value; }
    }

    void Start() {
        this.FacingRight = false;
        this.rb2d = GetComponent<Rigidbody2D>();
        this.chargeBar.gameObject.SetActive(false);
    }

    void Update() {
        if (this.Alive) {
            foreach (Vector3 rayPosition in this.rayPositions) {
                Debug.DrawRay(transform.position + rayPosition, Vector2.down * this.rayLength, Color.green);
            }

            if (Input.GetButtonUp("Fire1")) {
                if (this.heldBox != null && !this.boxJustPickedUp) {
                    this.DropBox();
                    this.chargeBar.gameObject.SetActive(false);
                } else {
                    this.boxJustPickedUp = false;
                }
            }

            if (Input.GetButton("Fire1")) {
                if (this.heldBox != null && !this.boxJustPickedUp) {
                    if (!this.chargeBar.gameObject.activeSelf) {
                        this.chargeBar.gameObject.SetActive(true);
                    }
                    this.throwForce += 1 + Mathf.Pow(( ( this.throwForceStep * Time.deltaTime ) / 1 ), 2);
                    if (this.throwForce > this.throwForceMax) {
                        this.throwForce = this.throwForceMax;
                    }
                }
            }

            if (Input.GetButtonDown("Fire1")) {
                if (this.heldBox == null && this.closestBox != null) {
                    this.PickUpBox();
                    this.boxJustPickedUp = true;
                }
            }
        }
    }

    void FixedUpdate() {
        if (this.Alive) {
            float moveHorizontal = Input.GetAxis("Horizontal");
            if (Input.GetButton("Jump")) {
                this.Jump();
            }
            //this.rb2d.AddForce(Vector2.right * moveHorizontal * this.speed);
            this.rb2d.velocity = new Vector2(moveHorizontal * this.maxSpeed, this.rb2d.velocity.y);
            this.clampHorizontalSpeed();
            this.Flip(moveHorizontal);

            if (this.heldBox == null) {
                Collider2D[] colliders = Physics2D.OverlapCircleAll(transform.position, this.pickUpRadius, 1 << LayerMask.NameToLayer("Entities"));
                List<Box> boxesInRange = new List<Box>();
                foreach (Collider2D collider in colliders) {
                    if (collider.gameObject.tag == "Box") {
                        boxesInRange.Add(collider.gameObject.GetComponent<Box>());
                    }
                }

                boxesInRange = boxesInRange.OrderBy(x => x, new BoxOrientationComparer(this)).ThenBy(x => x, new BoxDistanceComparer(this)).ToList();

                if (boxesInRange.Count > 0) {
                    this.setClosestBox(boxesInRange[0]);
                } else {
                    this.setClosestBox(null);
                }
            }
        }
    }

    private void DropBox() {
        Debug.Log("Dropping " + this.heldBox.gameObject.name);
        this.heldBox.transform.SetParent(null);
        this.heldBox.IsHeld = false;
        this.heldBox.Throw(new Vector2((this.FacingRight ? this.throwForce : -this.throwForce ),this.throwForce*this.throwForceVerticalAdjustment), new Vector2(this.rb2d.velocity.x, this.rb2d.velocity.y));
        this.heldBox = null;
        this.throwForce = 0f;
    }

    void PickUpBox() {
        Debug.Log("Picking up " + this.closestBox.gameObject.name);
        this.heldBox = this.closestBox;
        this.setClosestBox(null);
        this.heldBox.transform.SetParent(transform);
        this.heldBox.transform.position = this.holdPoint.position;
        this.heldBox.IsHeld = true;
    }

    void Jump() {
        if (this.isGrounded()) {
            this.rb2d.velocity = new Vector2(this.rb2d.velocity.y, 0);
            this.rb2d.AddForce(Vector2.up * this.jumpForce, ForceMode2D.Impulse);
        }
    }

    internal void Kill(string by) {

        this.KilledBy = by;

        if (this.KilledBy == "burner") {
            this.sprite.enabled = false;
        }

        this.Alive = false;
        this.FacingRight = false;
        if (this.heldBox != null) {
            this.heldBox.IsHeld = false;
            this.heldBox.Throw(Vector2.zero);
        }
        this.heldBox = null;
        this.closestBox = null;
        transform.eulerAngles = new Vector3(
            transform.eulerAngles.x,
            transform.eulerAngles.y,
            90
        );
    }

    void Flip(float moveHorizontal) {
        if (moveHorizontal > 0 && !this.FacingRight || moveHorizontal < 0 && this.FacingRight) {
            this.FacingRight = !this.FacingRight;
        }
    }

    void FlipSprite() {
        this.sprite.flipX = this.FacingRight;
    }

    private void UpdateHoldPosition() {
        this.holdPoint.transform.localPosition = new Vector3(( this.facingRight ? 1 : -1 ), 0, 0);
        if (this.heldBox != null) {
            this.heldBox.transform.position = this.holdPoint.position;
        }
    }

    void clampHorizontalSpeed() {
        var v = this.rb2d.velocity;
        var yd = v.y;
        v.y = 0f;
        v = Vector3.ClampMagnitude(v, this.maxSpeed);
        v.y = yd;
        this.rb2d.velocity = v;
    }

    private bool isGrounded() {
        bool grounded = false;
        int i = 0;
        while (!grounded && i < this.rayPositions.Length) {
            grounded = Physics2D.Raycast(transform.position + this.rayPositions[i++], Vector2.down, this.rayLength);
        }
        return grounded;
        
    }

    public float getChargePercent() {
        return (this.throwForce / this.throwForceMax) * 100f;
    }

    void setClosestBox(Box b) {
        if (this.closestBox != null) {
            this.closestBox.Highlight = false;
        }
        this.closestBox = b;
        if (this.closestBox != null) {
            this.closestBox.Highlight = true;
        }
    }

    private void OnDrawGizmosSelected() {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, this.pickUpRadius);
    }

}
