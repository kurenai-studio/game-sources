using UnityEngine;
using System.Collections;

public class FlightLook : MonoBehaviour {

    Transform target;

    public Vector3 offset = new Vector3(0, 1, -2);
    public float followDistance = 2f;
    public float followSpeed = 50f;
    public float followRotationSpeed = 500f;

    public void OnEnable()
    {
        findTarget();
    }

	// Update is called once per frame
    void FixedUpdate()
    {

        if (target == null)
            findTarget();
        if (target != null)
        {
            transform.rotation = target.rotation;
            transform.position = target.position + offset - transform.forward * followDistance;// * Vector3.Distance(transform.position, target.position + offset);
            //transform.position = Vector3.Slerp(transform.position, target.position +offset, Time.deltaTime * followSpeed);
        }
    }

    void findTarget()
    {
        if (target == null)
        {
            GameObject go = GameObject.FindGameObjectWithTag("Player");
            if (go != null)
            {
                target = go.transform;
            }
            else
            {
                Debug.Log("Camera couldn't Find Player");
                return;
            }
        }
        transform.rotation = target.rotation;
        transform.position = target.position + target.TransformDirection(offset) + target.forward * (-followDistance);
    }
}
