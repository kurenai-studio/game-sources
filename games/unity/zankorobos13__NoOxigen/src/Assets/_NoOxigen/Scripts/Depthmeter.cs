using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Depthmeter : MonoBehaviour
{
    void Update()
    {
        gameObject.GetComponent<RectTransform>().anchoredPosition = new Vector3(
            gameObject.GetComponent<RectTransform>().anchoredPosition.x,
            G.player.transform.position.y * 7.7f - 400f
        );
    }
}
