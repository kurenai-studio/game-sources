
using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class MeshRendererSortingLayer : MonoBehaviour
{

	[SerializeField]
	private string sortingLayerName;

	[SerializeField]
	private int sortingOrder;

	public void Start()
	{
		Renderer renderer = GetComponent<Renderer>();
		renderer.sortingLayerName = sortingLayerName;
		renderer.sortingOrder = sortingOrder;
	}
}