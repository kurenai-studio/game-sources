using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveBulletTrail : MonoBehaviour {

    public GameObject Owner = null;
    public float m_moveSpeed = 230f;
    public float m_destroyAfterSeconds = 1f;

    //Damage to deal to whoever gets hit
    public double Damage = 0;

    void Start()
    {
        StartCoroutine(DestoryAfter(m_destroyAfterSeconds));
    }

	void FixedUpdate()
    {
        transform.Translate(Vector3.right * Time.deltaTime * m_moveSpeed);
	}

    public void InitializeBullet(GameObject owner, double damage)
    {
        Owner = owner;
        Damage = damage;
    }

    IEnumerator DestoryAfter(float seconds)
    {
        yield return new WaitForSeconds(seconds);
        Destroy(this.gameObject);
    }

    /// <summary>
    /// Destroys the bullet trail early because it has hit a player/enemy
    /// </summary>
    public void DestroyEarly()
    {
        Destroy(this.gameObject);
    }
}
