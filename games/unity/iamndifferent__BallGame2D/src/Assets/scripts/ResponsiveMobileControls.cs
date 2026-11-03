
using UnityEngine;

public class ResponsiveMobileControls : MonoBehaviour
{
    [SerializeField] private GameObject mobileControls;
    [SerializeField] private GameObject deathPanel;

    private bool gameEnded = false;

    private void Start()
    {
        UpdateLayout();
    }

    private void Update()
    {
        UpdateLayout();
    }

    private void UpdateLayout()
    {
        bool isPortrait = Screen.height > Screen.width;

        bool deathVisible =
            deathPanel != null && deathPanel.activeInHierarchy;

        bool shouldShow = isPortrait &&
                          !gameEnded &&
                          !deathVisible;

        if (mobileControls != null &&
            mobileControls.activeSelf != shouldShow)
        {
            mobileControls.SetActive(shouldShow);
        }
    }

    public void HideMobileControls()
    {
        gameEnded = true;

        if (mobileControls != null)
        {
            mobileControls.SetActive(false);
        }
    }
}
