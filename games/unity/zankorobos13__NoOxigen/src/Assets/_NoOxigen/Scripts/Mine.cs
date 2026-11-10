using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Mine : MonoBehaviour
{
    public GameObject explosion_prefab;

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (collision.gameObject.tag == "Player")
        {
            Explode();
        }
    }

    private void Explode()
    {
        G.player.GetComponent<Player>().Damage(20f);
        Instantiate(explosion_prefab, gameObject.transform.position, gameObject.transform.rotation);
        G.OnMineExploded();
        Destroy(gameObject);
    }
}
