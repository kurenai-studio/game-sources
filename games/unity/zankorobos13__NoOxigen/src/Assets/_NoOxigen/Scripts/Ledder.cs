using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Ledder : MonoBehaviour
{
    public bool isTop;
    public GameObject signPrefab;
    private GameObject sign;
    private void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Human")
        {
            sign = Instantiate(signPrefab, gameObject.transform);
            sign.transform.localPosition = new Vector3(sign.transform.localPosition.x, sign.transform.localPosition.y + 1.2f, sign.transform.localPosition.z);

            collision.gameObject.GetComponent<Human>().isOnLedder = true;
            Vector3 new_player_pos;

            if (isTop)
                new_player_pos = gameObject.transform.parent.Find("Bot").position;
            else
                new_player_pos = gameObject.transform.parent.Find("Top").position;

            
            collision.gameObject.GetComponent<Human>().new_ledder_pos = new_player_pos;
        }
    }
    private void OnTriggerStay2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Human")
        {

            collision.gameObject.GetComponent<Human>().isOnLedder = true;
            Vector3 new_player_pos;

            if (isTop)
                new_player_pos = gameObject.transform.parent.Find("Bot").position;
            else
                new_player_pos = gameObject.transform.parent.Find("Top").position;


            collision.gameObject.GetComponent<Human>().new_ledder_pos = new_player_pos;
        }
    }

    private void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Human")
        {
            if (sign is not null)
                StartCoroutine(DestroySign());
            collision.gameObject.GetComponent<Human>().isOnLedder = false;
        }
    }

    private IEnumerator DestroySign()
    {
        sign.GetComponent<Animator>().SetBool("isNeedToDisappear", true);
        yield return new WaitForSeconds(0.3f);
        Destroy(sign);
    }

}
