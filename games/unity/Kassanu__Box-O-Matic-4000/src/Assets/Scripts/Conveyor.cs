using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Conveyor : MonoBehaviour {

    private bool gameOver = false;
    public bool GameOver {
        get { return this.gameOver; }
        set { this.gameOver = value; }
    }
    [SerializeField]
    private float crazySpeed = 10f;

    [SerializeField]
    private float minimumBeltSpeed = 1f;
    public float MinimumBeltSpeed {
        get { return this.minimumBeltSpeed; }
        set { this.minimumBeltSpeed = value; }
    }

    [SerializeField]
    private float maximumBeltSpeed = 2f;
    public float MaximumBeltSpeed {
        get { return this.maximumBeltSpeed; }
        set { this.maximumBeltSpeed = value; }
    }

    private float beltSpeed = 1f;
    public float BeltSpeed {
        get { return this.beltSpeed; }
        set {
            this.beltSpeed = ((value < this.MinimumBeltSpeed ) ? this.MinimumBeltSpeed : ((value > this.MaximumBeltSpeed) ? this.MaximumBeltSpeed : value));
        }
    }

    public float minKickStrength = 1f;

    
    [SerializeField]
    private float minimumKickStrength = 1f;
    public float MinimumKickStrength {
        get { return this.minimumKickStrength; }
        set { this.minimumKickStrength = value; }
    }

    [SerializeField]
    private float defaultMaximumKickStrength = 2f;
    public float DefaultMaximumKickStrength {
        get { return this.defaultMaximumKickStrength; }
        set { this.defaultMaximumKickStrength = value; }
    }

    [SerializeField]
    private float maximumKickStrength = 1f;
    public float MaximumKickStrength {
        get { return this.maximumKickStrength; }
        set { this.maximumKickStrength = value; }
    }

    private float currentMaximumKickStrength = 2f;
    public float CurrentMaximumKickStrength {
        get { return this.currentMaximumKickStrength; }
        set {
            this.currentMaximumKickStrength = ( ( value < this.minKickStrength ) ? this.minKickStrength : ( ( value > this.MaximumKickStrength ) ? this.MaximumKickStrength : value ) );
        }
    }

    void Start () {
		
	}
	
	void FixedUpdate () {
        foreach (Transform child in transform) {
            if (child.tag == "Box") {
                Box box = child.gameObject.GetComponent<Box>();
                box.Throw(Vector2.zero, new Vector2(this.GameOver ? this.crazySpeed:this.beltSpeed, box.GetVelocity().y));
            }
        }
    }

    public float RandomKickStrength() {
        return Random.Range(this.MinimumKickStrength, this.CurrentMaximumKickStrength);
    }

    public void AdjustConveyorSpeed(float percentage) {
        this.BeltSpeed = this.MinimumBeltSpeed + ((this.MaximumBeltSpeed - this.MinimumBeltSpeed) * percentage);
    }

    public void AdjustConveyorKick(float percentage) {
        this.CurrentMaximumKickStrength = this.DefaultMaximumKickStrength + ( ( this.MaximumKickStrength - this.DefaultMaximumKickStrength ) * percentage );
    }

}
