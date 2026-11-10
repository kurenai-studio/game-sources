using UnityEngine;
using UnityEngine.SceneManagement;

namespace LD55
{
    public class MainMenu : MonoBehaviour
    {
        #region Inspector

        [SerializeField] Transform _Music;

        #endregion

        public void OnStartGameClicked()
        {
            SceneManager.LoadScene(Consts.Level1Scene);
        }

        private void Start()
        {
            DontDestroyOnLoad(_Music);
        }
    }
}
