using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class GravityObject : MonoBehaviour
{

	protected void Awake()
	{
		transform.parent.GetComponent<PlanetarySystem>().registerConstantBody(GetComponent<Rigidbody2D>());
	}

	public void OnDrawGizmos()
	{
		float magnitude = transform.localPosition.magnitude;
        for (int i = 0; i < 360; i+=10)
		{
			Gizmos.DrawLine(
				transform.parent.position + new Vector3(Mathf.Cos(i*Mathf.Deg2Rad)*magnitude, Mathf.Sin(i * Mathf.Deg2Rad) * magnitude, 0),
				transform.parent.position + new Vector3(Mathf.Cos((i+10) * Mathf.Deg2Rad) * magnitude, Mathf.Sin((i+10) * Mathf.Deg2Rad) * magnitude, 0)
				);
        }
	}
}
