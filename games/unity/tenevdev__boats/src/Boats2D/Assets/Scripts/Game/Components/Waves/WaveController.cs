using UnityEngine;
using System.Collections;
using UnityEngine.EventSystems;

namespace Assets.Scripts.Game.Components
{
    /// <summary>
    /// Create waves based on user input
    /// </summary>
    public class WaveController : MonoBehaviour, IDragHandler, IEndDragHandler, IBeginDragHandler, IPointerClickHandler
    {
        public Transform ripple;
        public int dragInterval = 10;
        private int count = 0;

        public void OnPointerClick(PointerEventData eventData)
        {
            Instantiate(this.ripple, eventData.position, Quaternion.identity);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (this.count == this.dragInterval)
            {
                Instantiate(this.ripple, eventData.position, Quaternion.identity);
                count = 0;
            }
            else
            {
                count++;
            }
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            Instantiate(this.ripple, eventData.position, Quaternion.identity);
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            Instantiate(this.ripple, eventData.position, Quaternion.identity);
        }
    }
}