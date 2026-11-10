using UnityEngine;
using System.Collections;

public class Quest : MonoBehaviour {

	public static Quest instance { get; protected set; }

	public GameObject colony;
	public GameObject pirates;
	public GameObject warp;
	public GameObject q1;
	public GameObject q2;
	public GameObject q3;
	public GameObject q4;
	public GameObject q5;
	public GameObject end;
	public GameObject megaGate;

	private Ship player;

	[SerializeField]
	int travel = 0;
	[SerializeField]
	int grow = 0;

	void Awake () {
		instance = this;
		player = FindObjectOfType<Ship>();
	}

	public void Travel()
	{
		travel++;
		if(travel == 3)
		{
			q1.SetActive(true);
			q1.transform.SetAsLastSibling();
		}
		else if (travel == 4)
		{
			q2.SetActive(true);
			q2.transform.SetAsLastSibling();
		}
		else
		{
			warp.SetActive(true);
			warp.transform.SetAsLastSibling();
		}
	}

	public void Grow(int level)
	{
		if(travel >= 4)
		{
			if(level > 3 && grow == 0)
			{
				q3.SetActive(true);
				q3.transform.SetAsLastSibling();
				grow++;
			}
			else if (level > 4 && grow == 1)
			{
				q4.SetActive(true);
				q4.transform.SetAsLastSibling();
				grow++;
			}
			else if (level > 5 && grow == 2)
			{
				q5.SetActive(true);
				q5.transform.SetAsLastSibling();

                Vector2 pos = player.solarSystem.transform.position;
				Collider2D[] cols = Physics2D.OverlapCircleAll(pos, 100f);
				for (int i = 0; i < cols.Length; i++)
				{
					cols[i].gameObject.SetActive(false);
				}
				player.gameObject.SetActive(true);
				megaGate.transform.position = pos;
				megaGate.SetActive(true);
			}
			else
			{
				colony.SetActive(true);
				colony.transform.SetAsLastSibling();
			}
		}
		else
		{
			colony.SetActive(true);
			colony.transform.SetAsLastSibling();
		}
	}

	public void Pirates()
	{
		pirates.SetActive(true);
		pirates.transform.SetAsLastSibling();
	}

	public void End()
	{
		end.SetActive(true);
		AudioController.Tune();
	}
}
