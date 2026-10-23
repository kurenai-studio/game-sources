using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Snake : MonoBehaviour
{

	public Tail tailPrefab;
	
	[SerializeField]List<Tail> tail;

	PlayerController controller;


    // Start is called before the first frame update
    void Start()
    {
		controller = GetComponent<PlayerController>();
		tail = new List<Tail>();
	}

	void Update()
	{
		if(controller.GetDirection != Direction.NONE)
		{
			if (tail.Count != 0)
			{

				Vector3 lastPosition = transform.position;
				for (int i = 0; i < tail.Count; ++i)
				{
					tail[i].UpdatePosition(lastPosition);
					lastPosition = tail[i].transform.position;
				}
			}
		}
	}

	public void OnTriggerEnter2D(Collider2D collision)
	{
		if(collision.GetComponent<Fruit>())
		{
			Debug.Log("Getting Hit!");
			if (tail.Count != 0)
			{
				Tail go = Instantiate(tailPrefab, tail[tail.Count - 1].transform.position, 
					Quaternion.identity);

				tail.Add(go);
				collision.gameObject.GetComponent<Fruit>().DestroyMe();
				return;
			}
			Tail go1 = Instantiate(tailPrefab, transform.position, Quaternion.identity);
			tail.Add(go1);
			collision.gameObject.GetComponent<Fruit>().DestroyMe();
		}
	}




}
