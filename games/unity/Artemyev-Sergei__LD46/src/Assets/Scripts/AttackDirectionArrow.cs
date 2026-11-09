using UnityEngine;

public class AttackDirectionArrow : MonoBehaviour
{
	private float size = 0f;

	private SpriteRenderer arrowSprite;

	private void Awake()
	{
		this.arrowSprite = GetComponent<SpriteRenderer>();
	}

	private void Update()
	{
		this.arrowSprite.size = new Vector2(1f, this.size);
	}

	public void SetSize(float size)
	{
		this.size = size;
	}
}
