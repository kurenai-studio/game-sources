using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class red : MonoBehaviour
{
    public Text txt;
    public int grn = 0;
    public GameObject restart, greenball, redball,Startbtn;
    public float timecounter = 2, timecounter2 = 3;


    private void Start()
    {
        Time.timeScale = 0;
    }
    private void Update()
    {
        //Green counter
        timecounter -= Time.deltaTime;
        //Red counter
        timecounter2 -= Time.deltaTime;
        //Create a green ball
        if (timecounter<=0)
        {
            GameObject gb = Instantiate(greenball, new Vector3(Random.Range(-1.64f, 1.52f), 5.68f, 0),Quaternion.identity);
            timecounter = 2;
        }
        //Create a red ball
        if (timecounter2 <= 0)
        {
            GameObject go = Instantiate(redball, new Vector3(Random.Range(-1.64f, 1.52f), 5.68f, 0), Quaternion.identity);
            timecounter2 = 3;
        }

    }

    //Collision Method
    private void OnCollisionEnter2D(Collision2D collision)
    {
        //when something with a red tag touches it
        if (collision.gameObject.tag.Equals("red"))
        {
            grn = grn + 1;
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
            grn = grn - 3;
            txt.text = grn.ToString();
            Destroy(collision.gameObject);
            if (grn <= 0)
            {
                Time.timeScale = 0;
                restart.SetActive(true);
            }
        }
    }

    //Restart button method
    public void Restart()
    {
        SceneManager.LoadScene("SampleScene");
    }
    public void StartButton()
    {
        Time.timeScale = 1;
        Startbtn.SetActive(false);
    }

}
