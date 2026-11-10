using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Door : MonoBehaviour
{

    public GameObject signPrefab;
    public GameObject canvas;

    private bool isAbleForInteraction = true;
    private GameObject sign;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (isAbleForInteraction && Input.GetKeyDown(KeyCode.E))
            SceneManager.LoadScene("Main");
    }

    private void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Human")
        {
            isAbleForInteraction = true;
            sign = Instantiate(signPrefab, gameObject.transform);
            sign.transform.localPosition = new Vector3(sign.transform.localPosition.x, sign.transform.localPosition.y + 1.2f, sign.transform.localPosition.z);
        }
    }

    private void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Human")
        {
            isAbleForInteraction = false;
            if (sign is not null && this is not null && gameObject is not null && gameObject.activeSelf)
                StartCoroutine(DestroySign());
        }
    }

    private IEnumerator DestroySign()
    {
        if (this is null || gameObject is null)
            yield break;
        sign.GetComponent<Animator>().SetBool("isNeedToDisappear", true);
        yield return new WaitForSeconds(0.3f);
        if (this is null || gameObject is null)
            yield break;
        Destroy(sign);
    }
}
