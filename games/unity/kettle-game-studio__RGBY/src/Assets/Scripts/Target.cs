using UnityEngine;
using UnityEngine.SceneManagement;

public class Target : MonoBehaviour
{
    void OnTriggerEnter(Collider other) {
        var player = other.GetComponent<PlayerController>();
        if (player != null) {
            SceneManager.LoadScene(gameObject.scene.buildIndex+1);
        }
    }
}
