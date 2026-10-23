using UnityEngine;

public class Shooting : MonoBehaviour
{
    [SerializeField] private GameObject bananaPrefab;

    void Start()
    {
        
    }
    
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            CreateBanana();
        }
        
        if (Input.GetMouseButtonDown(1))
        {
            CreateBomb();
        }
    }

    private void CreateBanana()
    {
        GameObject banana = Instantiate(bananaPrefab);
        banana.transform.position = gameObject.transform.position;
    }

    private void CreateBomb()
    {
        GameObject bomb = Instantiate(bananaPrefab);
        bomb.transform.position = gameObject.transform.position;
    }
}
