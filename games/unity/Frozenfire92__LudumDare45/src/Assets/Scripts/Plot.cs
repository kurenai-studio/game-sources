using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Plot : MonoBehaviour
{
    private bool showMessage = false;
    public int resourceCount = 0;
    public Canvas c;

    public void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.gameObject.CompareTag("Resources"))
        {
            resourceCount++;
        }
    }

    public void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.gameObject.CompareTag("Resources"))
        {
            resourceCount--;
        }
    }

    public void ShowMessage()
    {
        if (resourceCount <= 0)
        {
            showMessage = true;
            c.gameObject.SetActive(true);
        }
    }

    public void HideMessage()
    {
        showMessage = false;
        c.gameObject.SetActive(false);
    }
}
