using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public GameObject main_camera;
    public float left_border = 0;
    public float right_border = 36;

    void Start()
    {
        G.MineExploded += OnMineExploded;
        G.ModeChanged += OnModeChanged;
    }

    void Update()
    {
        if (G.player.GetComponent<Player>().isAbleToControl)
            FollowPlayer();
    }

    private void FollowPlayer()
    {
        float camera_x = G.player.transform.position.x;
        float camera_y = G.player.transform.position.y;

        if (camera_x < left_border)
            camera_x = left_border;
        if (camera_x > right_border)
            camera_x = right_border;

        main_camera.transform.position = new Vector3(camera_x, camera_y, main_camera.transform.position.z);
    }

   
    private IEnumerator Shake(float duration, float magnitude)
    {
        Vector3 initial_position = main_camera.transform.position;

        float elapsed = 0f;

        while (elapsed < duration)
        {
            float delta_x = Random.Range(-1f, 1f) * magnitude;
            float delta_y = Random.Range(-1f, 1f) * magnitude;

            main_camera.transform.position = new Vector3(initial_position.x + delta_x, initial_position.y + delta_y, initial_position.z);

            elapsed += Time.deltaTime;

            yield return null;
        }
    }

    private IEnumerator ZoomToPlayer(float duration)
    {
        Vector2 initilal_position = main_camera.transform.position;
        float initial_size = main_camera.GetComponent<Camera>().orthographicSize;

        float elapsed = 0f;

        while (elapsed < duration)
        {
            float x = Mathf.Lerp(initilal_position.x, G.player.transform.position.x, elapsed/duration);
            float y = Mathf.Lerp(initilal_position.y, G.player.transform.position.y, elapsed/duration);
            float size = Mathf.Lerp(initial_size, 3.2f, elapsed/duration);

            main_camera.transform.position = new Vector3(x, y, main_camera.transform.position.z);
            main_camera.GetComponent<Camera>().orthographicSize = size;

            elapsed += Time.deltaTime;

            yield return null;
        }

        main_camera.transform.position = new Vector3(G.player.transform.position.x, G.player.transform.position.y, main_camera.transform.position.z);
        main_camera.GetComponent<Camera>().orthographicSize = 3.2f;
    }

    private void OnMineExploded()
    {
        StartCoroutine(Shake(0.7f, 1f));
    }

    private void OnModeChanged()
    {
        StartCoroutine(ZoomToPlayer(2f));
    }
}
