
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameManagerUI : MonoBehaviour
{
    public GameObject deathPanel;
    public GameObject mobileControls;

    private bool hasEnded = false;

    public void ShowDeath()
    {
        // Evitar ejecutar la muerte varias veces
        if (hasEnded)
            return;

        hasEnded = true;

        // Mostrar la pantalla de muerte
        if (deathPanel != null)
        {
            deathPanel.SetActive(true);
        }

        // Ocultar los controles táctiles
        ResponsiveMobileControls controls =
            FindFirstObjectByType<ResponsiveMobileControls>();

        if (controls != null)
        {
            controls.HideMobileControls();
        }

        // Pausar la partida
        Time.timeScale = 0f;
    }

    public void RestartGame()
    {
        Time.timeScale = 1f;

        SceneManager.LoadScene(
            SceneManager.GetActiveScene().buildIndex
        );
    }
}
