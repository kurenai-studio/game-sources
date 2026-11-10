using UnityEngine;
using System.Collections;

public class ShipHealth : MonoBehaviour {

    public float maxHealth = 1000f;

    [SerializeField]
    [Header("Debug Only")]
    private float health = 1000f;
    [SerializeField]
    private bool enemy = true;

    virtual public float Health { get { return health; } set { health = value; CheckDeath(); } }
    virtual public bool Enemy { get { return enemy; } set { enemy = value; } }

    void Start()
    {
        health = maxHealth;
    }

    public void  Damage(float amount)
    {
        Health -= amount;
    }

    public void CheckDeath() 
    {
        if (Health < 0)
        {
            if (Enemy)
                GameObject.FindObjectOfType<GamestateManager>().Win();
            else
                GameObject.FindObjectOfType<GamestateManager>().Die();
        }

    }

    public float getHealthPercent()
    {
        return Health / maxHealth;
    }
}
