using UnityEngine;
using System.Collections;
using UnityEngine.UI;

namespace Assets.Scripts.UI
{
    public class StoryManager : MonoBehaviour
    {

        // Setup level buttons' colors
        // Calculate game completion percentage

        private int completeLevel;
        private float levelCount = 3;

        public Image completionBar;

        // Use this for initialization
        void Start()
        {
            this.completeLevel = PlayerPrefs.GetInt("LastLevel", 0);
            for (int i = 0; i < this.completeLevel; i++)
            {
                GameObject.Find("Level " + (i + 1) + " Button").GetComponent<Image>().color = Color.green;
            }


            this.completionBar.color = Color.Lerp(Color.red, Color.green, this.completeLevel / this.levelCount);
            this.completionBar.GetComponent<RectTransform>().localScale = Vector3.Lerp(new Vector3(1, 1, 1), new Vector3(10, 1, 1), this.completeLevel / this.levelCount);
        }

        public void LoadLevel(int index)
        {
            if (index <= this.completeLevel + 1)
            {
                Application.LoadLevel(index);
            }
        }

        // Update is called once per frame
        void Update()
        {

        }
    }
}