using UnityEngine;

public class Tail : MonoBehaviour
{
	public float power = 0.2f;

	public void UpdatePosition(Vector3 position)
	{
		//Vector2 calc = new Vector2(transform.position.x + (position.x - transform.position.x) * power, 
		//	transform.position.y + (position.y - transform.position.y) * power);

		transform.position = Vector3.Lerp(transform.position, position, power);
	}
}
