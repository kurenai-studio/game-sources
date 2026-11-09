using UnityEngine;

public class Sword : MonoBehaviour
{
    public SwordController swordController;

    void OnTriggerEnter(Collider other)
    {
        if (other.TryGetComponent<Enemy>(out var enemy))
        {
            enemy.GetHit(swordController.transform, swordController.SwordDamage);
        }

        if (other.attachedRigidbody.TryGetComponent<Dragon>(out var dragon))
        {
            dragon.getShot = true;
            dragon.health -= swordController.SwordDamage;
            // enemy.GetHit(swordController.transform, swordController.SwordDamage);
        }
    }
}
