using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Collider))]
public class Crop : MonoBehaviour
{
    [Min(0)] public float randomAngle = 2f;
    [Min(0)] public float randomLocation = 0.1f;
    [Min(0)] public float randomHeight = 0.1f;
    public LayerMask groundLayerMask = 1 << 3;

    private void Start()
    {
        var pos = transform.position;
        pos += Random.insideUnitSphere * randomLocation;
        pos.y -= Random.value * randomHeight;
        var rot = Quaternion.Euler(Random.value * randomAngle, Random.value * 360f, 0f);
        transform.SetPositionAndRotation(pos, rot);
    }

    private void OnTriggerEnter(Collider other)
    {
        if ((other.gameObject.layer ^ groundLayerMask) != 0)
        {
            var tresher = other.GetComponent<Tresher>();
            if (tresher != null)
            {
                tresher.Harvest();
                // TODO: Destroy crop FX
            }
            Destroy(gameObject);
        }
    }
}
