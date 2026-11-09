using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(SquadCollisions))]
public class Squad : MonoBehaviour
{
	public EventSquadDefeated EventSquadDefeated = new EventSquadDefeated();

	private Rigidbody2D body2D;
	private CircleCollider2D collider2D;

	private MeshRenderer bannerRenderer;
	private TextMesh bannerText;

	[SerializeField]
	private SquadData squadData;

	private List<GameObject> units = new List<GameObject>();

	private int CurrentUnitsCount
	{
		get
		{
			return this.units.Count;
		}
	}

	public bool IsDeafeated
	{
		get
		{
			return CurrentUnitsCount <= 0;
		}
	}

	private float squadAttackingForce = 0.1f;
	private string squadSortingLayer = "Squad";

	private void Awake()
	{
		this.body2D = GetComponent<Rigidbody2D>();
		this.collider2D = GetComponent<CircleCollider2D>();

		this.bannerRenderer = GetComponentInChildren<MeshRenderer>(true);
		this.bannerText = GetComponentInChildren<TextMesh>(true);
	}

	private void Start()
	{
		this.bannerText.transform.localPosition = new Vector3(0f, this.squadData.SquadOccupiedSpace + 0.5f, -10f);
		this.bannerRenderer.sortingLayerName = this.squadSortingLayer;
		this.bannerRenderer.sortingOrder = 2;

		AssembleSquad(this.squadData.UnitsCount);
	}

	/// <summary>
	/// Assemble squad of given units count
	/// </summary>
	/// <param name="newUnitsCount"></param>
	private void AssembleSquad(int newUnitsCount)
	{
		DisbandSquad();

		if (newUnitsCount <= 0)
		{
			this.gameObject.SetActive(false);
			return;
		}

		for (int i = 0; i < newUnitsCount; ++i)
		{
			GameObject gameObject = new GameObject("Unit");
			gameObject.transform.parent = this.gameObject.transform;

			// Place units within a circle based on this: https://stackoverflow.com/questions/5837572/generate-a-random-point-within-a-circle-uniformly/50746409#50746409
			float r = this.squadData.SquadOccupiedSpace * Mathf.Sqrt(Random.Range(0f, 1f));
			float angle = Random.Range(0f, 1f) * 2 * Mathf.PI;
			Vector3 spawnPosition = new Vector3(
				this.gameObject.transform.position.x + r * Mathf.Cos(angle), 
				this.gameObject.transform.position.y + r * Mathf.Sin(angle), 
				this.gameObject.transform.position.y + r * Mathf.Sin(angle));

			gameObject.transform.localPosition = spawnPosition;
			gameObject.transform.position = new Vector3(gameObject.transform.position.x, gameObject.transform.position.y, gameObject.transform.position.y);

			SpriteRenderer spriteRenderer = gameObject.AddComponent<SpriteRenderer>();
			spriteRenderer.sprite = this.squadData.UnitSprite;
			spriteRenderer.sortingLayerName = this.squadSortingLayer;

			this.units.Add(gameObject);
		}
		
		this.CenterUnits();

		this.bannerText.text = string.Format("{0}", CurrentUnitsCount);

		this.collider2D.radius = this.squadData.SquadOccupiedSpace + 0.5f;
	}

	private void DisbandSquad()
	{
		foreach (GameObject unit in this.units)
		{
			Destroy(unit);
		}
		this.units.Clear();
	}

	[ContextMenu("Center Units")]
	private void CenterUnits()
	{
		Vector2 positionSum = new Vector2(0f, 0f);
		foreach (GameObject gameObject in this.units)
		{
			positionSum.x += gameObject.transform.localPosition.x;
			positionSum.y += gameObject.transform.localPosition.y;
		}

		positionSum.x /= CurrentUnitsCount;
		positionSum.y /= CurrentUnitsCount;

		foreach (GameObject gameObject in this.units)
		{
			gameObject.transform.localPosition += new Vector3(0f - positionSum.x, 0f - positionSum.y, 0f - positionSum.y);
		}
	}

	public void SetBannerColor(Color color)
	{
		this.bannerText.color = color;
	}

	public void ResetSquadAttackingState()
	{
		this.squadAttackingForce = 0.1f;
	}

	public ESquadType GetSquadType()
	{
		return this.squadData.SquadType;
	}

	public float GetSquadMovementSpeed()
	{
		return this.squadData.SquadMovementSpeed;
	}

	public int GetSquadDamage()
	{
		return (int) (this.squadAttackingForce * (1f + this.squadData.SquadMovementSpeed / 10000f) * (float)(CurrentUnitsCount / 2));
	}

	public void Move(float force, Vector2 direction)
	{
		this.squadAttackingForce = force;
		this.body2D.AddForce(force * direction * this.squadData.SquadMovementSpeed, ForceMode2D.Force);
	}

	public void TakeDamage(int unitsKilled)
	{
		AssembleSquad(CurrentUnitsCount - unitsKilled);
		if (CurrentUnitsCount <= 0)
		{
			EventSquadDefeated.Dispatch(this);
		}
	}
}
