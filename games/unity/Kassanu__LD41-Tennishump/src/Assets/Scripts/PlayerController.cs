using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour {

    [SerializeField] float playerSpeed = 1f;
    [SerializeField] int health = 3;
    public int Health
    {
        get
        {
            return health;
        }

        set
        {
            health = value;
        }
    }

    // Use this for initialization
    void Start () {
	}
	
	// Update is called once per frame
	void Update () {
        GetInput();
	}

    private void GetInput()
    {
        if (Input.GetKey(KeyCode.A))
        {
            transform.Translate(Vector3.left * playerSpeed * Time.deltaTime);
        }
        else if(Input.GetKey(KeyCode.D))
        {
            transform.Translate(Vector3.right * playerSpeed * Time.deltaTime);
        }
    }

    public void DamagePlayer (int damageTaken) {
        this.Health -= damageTaken;
    }

    public bool IsAlive() {
        return this.Health > 0;
    }

}
