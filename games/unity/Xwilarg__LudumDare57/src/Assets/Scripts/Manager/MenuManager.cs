using UnityEngine;
using UnityEngine.SceneManagement;

namespace LudumDare57.Manager
{
    public class MenuManager : MonoBehaviour
    {
        public void Restart()
        {
            SceneManager.LoadScene("Main");
        }
    }
}