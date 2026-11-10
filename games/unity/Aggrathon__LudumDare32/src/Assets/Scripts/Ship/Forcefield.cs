using UnityEngine;
using System.Collections;

public class Forcefield : MonoBehaviour {

    public GameObject impact;

    public float maxEnergy = 1000f;
    public float energyRegeneration = 40f;
    public float energyDrain = 10f;
    public float rechargeTime = 5f;

    [Header("Only for debug")]
    public float energy;
    public float recharge;

    void Start()
    {
        energy = maxEnergy;
        recharge = rechargeTime;
    }

    void Update()
    {
        if (energy < maxEnergy)
            energy += energyRegeneration * Time.deltaTime;
        if (recharge < rechargeTime)
            recharge += Time.deltaTime;
    }

    public void OnTriggerEnter(Collider other)
    {
        if (other.tag == "Player" || recharge < rechargeTime)
            return;
        if (energy < energyDrain)
        {
            recharge = 0f;
            return;
        }

        energy -= energyDrain;
        SimplePool.Spawn(impact, other.transform.position, Quaternion.Euler(-other.transform.forward));
        SimplePool.Despawn(other.gameObject);
    }

    public float getShieldEnergyPercent()
    {
        if (recharge < rechargeTime)
            return 0f;
        return energy / maxEnergy;
    }

	
}
