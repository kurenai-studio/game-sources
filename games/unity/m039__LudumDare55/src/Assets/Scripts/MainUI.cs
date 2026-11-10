using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace LD55
{
    public class MainUI : MonoBehaviour
    {
        public static MainUI Instance;

        #region Inspector

        [SerializeField] RectTransform _IngredientsInfo;

        [SerializeField] RectTransform _AltarActivationInfo;

        [SerializeField] RectTransform _TutorialInfo;

        [SerializeField] RectTransform _Inventory;

        [SerializeField] RectTransform _WinScreen;

        [SerializeField] RectTransform _LoseScreen;

        #endregion

        List<RectTransform> _infos;

        void Awake()
        {
            Instance = this;
            Init();
        }

        void Init()
        {
            _infos = new()
            {
                _IngredientsInfo,
                _AltarActivationInfo,
                _TutorialInfo
            };
        }

        void Start()
        {
            ShowInfo(null);
            ShowInventory(null);

            _WinScreen.gameObject.SetActive(false);
            _LoseScreen.gameObject.SetActive(false);
        }

        public void ShowInventory(IList<Ingredient> ingredients)
        {
            if (ingredients == null || ingredients.Count <= 0)
            {
                _Inventory.gameObject.SetActive(false);
                return;
            }

            _Inventory.gameObject.SetActive(true);

            var template = _Inventory.transform.Find("List/Template");
            var list = _Inventory.transform.Find("List");

            for (int i = list.childCount - 1; i >= 0; i--)
            {
                var child = list.GetChild(i);
                if (child != template)
                {
                    Destroy(child.gameObject);
                }
            }

            template.gameObject.SetActive(false);

            foreach (var ingredient in ingredients)
            {
                var item = Instantiate(template, list, false);
                item.gameObject.SetActive(true);
                item.GetComponent<Image>().color = ingredient.color;
            }
        }

        public void ShowIngredientsInfo(IList<Ingredient> ingredients)
        {
            var template = _IngredientsInfo.transform.Find("List/Template");
            var list = _IngredientsInfo.transform.Find("List");

            for (int i = list.childCount - 1; i >= 0; i--)
            {
                var child = list.GetChild(i);
                if (child != template)
                {
                    Destroy(child.gameObject);
                }
            }

            template.gameObject.SetActive(false);

            foreach (var ingredient in ingredients)
            {
                var item = Instantiate(template, list, false);
                item.gameObject.SetActive(true);
                item.GetComponent<Image>().color = ingredient.color;
            }

            ShowInfo(_IngredientsInfo);
        }

        public void HideIngredientsInfo()
        {
            HideInfo(_IngredientsInfo);
        }

        public void ShowAltarActivationInfo()
        {
            ShowInfo(_AltarActivationInfo);
        }

        public void HideAltarActivationInfo()
        {
            HideInfo(_AltarActivationInfo);
        }

        public void ShowTutorialInfo()
        {
            ShowInfo(_TutorialInfo);
        }

        public void HideTutorialInfo()
        {
            HideInfo(_TutorialInfo);
        }

        void ShowInfo(RectTransform info)
        {
            foreach (var infoTmp in _infos)
            {
                infoTmp.gameObject.SetActive(infoTmp == info);
            }
        }

        void HideInfo(RectTransform info)
        {
            info.gameObject.SetActive(false);
        }

        public void ShowWinScreen()
        {
            _WinScreen.gameObject.SetActive(true);
        }

        public void ShowLoseScreen()
        {
            _LoseScreen.gameObject.SetActive(true);
        }

        public void OnRestartLevelClicked()
        {
            GameController.Instance.RestartLevel();
        }

        public void OnNextLevelClicked()
        {
            GameController.Instance.NextLevel();
        }
    }
}
