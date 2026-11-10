using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bot : MonoBehaviour
{
    private bool busy;
    private Animator animator;
    public GameObject target;

    void Awake()
    {
        animator = GetComponent<Animator>();
    }

    public void StartBeam(float searchTime = 1f)
    {
        if (!busy)
        {
            StartCoroutine(HandleBeam(searchTime));
        }
    }

    private void OnDisable()
    {
        StopAllCoroutines();
        busy = false;
    }

    public void Move(Transform t)
    {
        transform.position = new Vector3(t.position.x, t.position.y + 1, t.position.z);
    }

    IEnumerator HandleBeam(float searchTime)
    {
        busy = true;
        animator.SetBool("Beaming", true);
        yield return new WaitForSeconds(searchTime);
        animator.SetBool("Beaming", false);
        yield return new WaitForSeconds(1f);
        GameController.instance.botsAvailable++;
        GameController.instance.resources += (int)(searchTime * GameController.instance.botCollectionSpeed);
        UIController.instance.UpdateBots();
        UIController.instance.UpdateResources();
        Destroy(target);
        gameObject.SetActive(false);
    }
}
