using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class FlightController : MonoBehaviour {

    public float enginePower = 600f;
    public float engineReversePower = 400f;
    public float engineBoostMultiplier = 2.5f;
    public float turnPower = 10f;

    public float destroySpeed = 20f;

    public static float sensitivity = 5f;
    //public GameObject bombs;

    new private Rigidbody rigidbody;

	// Use this for initialization
	void Start () {
        rigidbody = GetComponent<Rigidbody>();
        //bombs = null;
	}
	
	// Update is called once per frame
	void Update () {
        if (Input.GetButtonUp("Fire") && Time.deltaTime > 0f)
        {
            GameObject bombs = GameObject.FindObjectOfType<GamestateManager>().bomb;
            if (bombs != null)
            {
                GameObject go = SimplePool.Spawn(bombs, transform.position - transform.up, transform.rotation);
                go.SetActive(true);
                Rigidbody rb = go.GetComponent<Rigidbody>();
                if (rb != null)
                {
                    rb.velocity = rigidbody.velocity - transform.up;
                }
            }
        }
	
	}

    void FixedUpdate()
    {
        float roll = (Input.GetAxis("Mouse X") + Input.GetAxis("Controller X"))
             * sensitivity * turnPower * Time.fixedDeltaTime;
        float pitch = (Input.GetAxis("Mouse Y") + Input.GetAxis("Controller Y")) 
            * sensitivity * turnPower * Time.fixedDeltaTime;
        float yaw = Input.GetAxis("Horizontal") * turnPower * Time.fixedDeltaTime;
        float throttle = Input.GetAxis("Vertical");

        if (throttle > 0)
        {
            if (Input.GetButton("Boost"))
                throttle *= engineBoostMultiplier; 
            rigidbody.AddForce(transform.forward * throttle * enginePower * Time.fixedDeltaTime, ForceMode.Acceleration);
        }
        else
            rigidbody.AddForce(transform.forward * throttle * engineReversePower * Time.fixedDeltaTime, ForceMode.Acceleration);

        Vector3 torque =
            -transform.forward * roll +
            transform.up * yaw +
            transform.right * pitch;

        rigidbody.AddTorque(torque, ForceMode.Acceleration);
        //Debug.Log("roll: " + roll + " pitch: " + pitch + " yaw: " + yaw + " throttle: " + throttle);
    }



    public void OnCollisionEnter(Collision collision)
    {
        if(collision.relativeVelocity.magnitude > destroySpeed)
            GameObject.FindObjectOfType<GamestateManager>().Die();
    }

    
}
