using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace JGM.UI.Turrets
{
    public class TurretCard : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        [SerializeField] private Image icon;
        [SerializeField] private TextMeshProUGUI priceText;
        [SerializeField] private CanvasGroup canvasGroup;

        private TurretCardModel model;
        private TurretShop turretShop;
        private bool canPlayerBuyCard;

        public void Initialize(TurretCardModel model, TurretShop turretShop)
        {
            this.model = model;
            icon.color = model.Color;
            priceText.text = model.Price.ToString();
            this.turretShop = turretShop;
        }

        public void OnBeginDrag(PointerEventData eventData)
        {

        }

        public void OnDrag(PointerEventData eventData)
        {

        }

        public void OnEndDrag(PointerEventData eventData)
        {
            if (canPlayerBuyCard)
            {
                turretShop.OnTurretCardDropped(model, eventData.position);
            }
        }

        public void RefreshCardIsAvailable(int coins)
        {
            canPlayerBuyCard = (coins >= model.Price);
            canvasGroup.alpha = canPlayerBuyCard ? 1f : 0.5f;
        }
    }
}
