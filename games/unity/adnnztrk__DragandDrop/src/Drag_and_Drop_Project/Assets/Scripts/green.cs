using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class green : MonoBehaviour
{
    public Text txt;
    public int grn = 0;
    public GameObject restart;
    //Collision Method
    private void OnCollisionEnter2D(Collision2D collision)
    {
        //when something with a red tag touches it
        if (collision.gameObject.tag.Equals("red"))
        {
            grn = grn - 3;
            txt.text = grn.ToString();
            Destroy(collision.gameObject);
            if (grn <= 0)
            {
                Time.timeScale = 0;
                restart.SetActive(true);
            }
        }
        //when something with a green tag touches it
        if (collision.gameObject.tag.Equals("green"))
        {
            grn = grn + 1;
            txt.text = grn.ToString();
            Destroy(collision.gameObject);
            if (grn<=0)
            {
                Time.timeScale = 0;
                restart.SetActive(true);
            }
        }
    }
}
