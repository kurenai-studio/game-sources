using UnityEngine;
using UnityEngine.UIElements;

namespace UI
{
    public class MainMenuController : MonoBehaviour
    {
        private VisualElement root;
        private Button playButton;
    
        private void Awake()
        {
            root = GetComponent<UIDocument>().rootVisualElement;
        
            playButton = root.Q<Button>("play__button");
        }

        private void OnEnable()
        {
            playButton.clicked += OnPlayClicked;
        }

        private void OnDisable()
        {
            playButton.clicked -= OnPlayClicked;
        }
        
        private void OnPlayClicked()
        {
            GameManager.Instance.StartGame();
        
            gameObject.SetActive(false);
        }
    }
}
