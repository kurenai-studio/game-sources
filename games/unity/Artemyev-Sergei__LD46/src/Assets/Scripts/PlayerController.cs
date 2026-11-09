using UnityEngine;

public class PlayerController : SquadController
{
	private Squad selectedSquad;
	private Vector2 attackDirection = new Vector2();

	private Vector2 selectionPoint = new Vector2();
	private AttackDirectionArrow attackDirectionArrow;
	private float maxRaycastDepth = 1000f;
	private bool canAttack = false;

	public PlayerController(AttackDirectionArrow attackDirectionArrow)
	{
		this.attackDirectionArrow = attackDirectionArrow;
	}

	public override void TakeTurn()
    {
		if (Input.GetMouseButtonDown(0))
		{
			SelectSquad();
		}
		
		if (Input.GetMouseButton(0))
		{
			if (this.selectedSquad != null)
			{
				PrepareAttack();
			}
		}

		if (Input.GetMouseButtonUp(0))
		{
			if (this.selectedSquad != null && this.canAttack)
			{
				Attack();
				this.squadsMoved++;
			}
		}
	}

	private void SelectSquad()
	{
		Ray ray = CameraController.Instance.Camera.ScreenPointToRay(Input.mousePosition);
		RaycastHit2D hit = Physics2D.Raycast(ray.origin, ray.direction, this.maxRaycastDepth);
		if (hit)
		{
			GameObject hitGameObject = hit.transform.gameObject;
			if (hitGameObject.CompareTag("Player"))
			{
				this.selectedSquad = hitGameObject.GetComponent<Squad>();
				this.selectionPoint = Input.mousePosition;
			}
		}
	}

	private void PrepareAttack()
	{
		this.attackDirection = new Vector2(Input.mousePosition.x / (float)(Screen.width / 2), Input.mousePosition.y / (float)(Screen.height / 2)) - new Vector2(this.selectionPoint.x / (float)(Screen.width / 2), this.selectionPoint.y / (float)(Screen.height / 2));
		if (this.attackDirection.magnitude > 0.1f)
		{
			float attackDirectionArrowSize = Mathf.Min(this.attackDirection.magnitude * 2f, 1f) * 20f;
			this.attackDirectionArrow.gameObject.SetActive(true);
			this.attackDirectionArrow.SetSize(attackDirectionArrowSize);
			this.attackDirectionArrow.transform.position = this.selectedSquad.transform.position;
			this.attackDirectionArrow.transform.rotation = LookAt2DCustom(attackDirection.normalized);
			this.canAttack = true;
		}
		else
		{
			this.attackDirectionArrow.gameObject.SetActive(false);
			this.canAttack = false;
		}
	}

	private void Attack()
	{
		this.attackDirectionArrow.gameObject.SetActive(false);

		Debug.Log(Mathf.Min(this.attackDirection.magnitude * 2f, 1f));
		this.selectedSquad.Move(Mathf.Min(this.attackDirection.magnitude * 2f, 1f), -this.attackDirection.normalized);
		this.canAttack = false;
		this.selectedSquad = null;
	}

	private Quaternion LookAt2DCustom(Vector2 forward)
	{
		return Quaternion.Euler(0f, 0f, Mathf.Atan2(forward.y, forward.x) * Mathf.Rad2Deg + 90f);
	}
}
