using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

[RequireComponent(typeof(EventTrigger))]
public class CardUI : MonoBehaviour
{

    public BaseCard card;
    public Image sprite;
    public TMPro.TextMeshProUGUI description;
    public TMPro.TextMeshProUGUI energy;
    public TMPro.TextMeshProUGUI nameText;
    public Image border;

    EventTrigger eventTrigger;
    public LineRenderer line1;
    public LineRenderer line2;
    bool dragging = false;
    Camera cam;
    DeckManager manager;

    public void Setup(BaseCard card, DeckManager manager) {
        this.card = card;
        sprite.sprite = card.sprite;
        description.text = card.GetDescription();
        energy.text = card.cost.ToString();
        this.manager = manager;
        var col = card.color;
        col.a = 1f;
        border.color = col;
        nameText.text = card.cardName;
        nameText.color = col;

        cam = Camera.main;
        line1.enabled = false;
        line2.enabled = false;
        line2.startColor = card.color;
        line2.endColor = card.color;
        line1.transform.rotation = Quaternion.LookRotation(-transform.up, transform.forward);
        line2.transform.rotation = Quaternion.LookRotation(-transform.up, transform.forward);

        eventTrigger = GetComponent<EventTrigger>();
        var start = new EventTrigger.Entry();
        start.eventID = EventTriggerType.BeginDrag;
        start.callback.AddListener((d) => OnBeginDrag((PointerEventData)d));
        eventTrigger.triggers.Add(start);
        var drag = new EventTrigger.Entry();
        drag.eventID = EventTriggerType.Drag;
        drag.callback.AddListener((d) => OnDrag((PointerEventData)d));
        eventTrigger.triggers.Add(drag);
        var stop = new EventTrigger.Entry();
        stop.eventID = EventTriggerType.PointerUp;
        stop.callback.AddListener((d) => OnPointerUp((PointerEventData)d));
        eventTrigger.triggers.Add(stop);
    }
    

    private void OnBeginDrag(PointerEventData eventData) {
        if (!manager.interactable || manager.energy < card.cost) {
            if (!manager.interactable) {
                manager.Alert("Not your turn!");
            } else {
                manager.Alert("Not enough energy!");
            }
            dragging = false;
            line1.enabled = false;
            line2.enabled = false;
            manager.board.Unlight();
        }
        dragging = true;
        line1.enabled = true;
        line2.enabled = true;
        var pos = Utils.GetGroundIntersect(cam.ScreenPointToRay(transform.position * 1.05f), 2f);
        line1.SetPosition(0, pos);
        line1.SetPosition(1, pos);
        line2.SetPosition(0, pos);
        line2.SetPosition(1, pos);
        switch (card.target)
        {
            case BaseCard.Target.Empty:
                manager.board.Highlight((BoardTarget b) => b.unit == null);
                break;
            case BaseCard.Target.Global:
                manager.board.Highlight((_) => true);
                break;
            case BaseCard.Target.Enemy:
                manager.board.Highlight((BoardTarget b) => b.unit != null && b.unit.team != manager);
                break;
            case BaseCard.Target.Friendly:
                manager.board.Highlight((BoardTarget b) => b.unit?.team == manager);
                break;
            case BaseCard.Target.Spawn:
                manager.board.Highlight((BoardTarget b) => b.unit == null && Utils.Vector3InBox(manager.transform.position, manager.spawnPositionLimit, b.transform.position));
                break;
        }
    }

    private void OnPointerUp(PointerEventData eventData) {
        if (dragging && !EventSystem.current.IsPointerOverGameObject(eventData.pointerId)) {
            BoardTarget target = null;
            RaycastHit hit;
            if (Physics.Raycast(cam.ScreenPointToRay(eventData.position), out hit, 100f)) {
                target = hit.transform.GetComponent<BoardTarget>();
            }
            if (card.Cast(target, manager))
                Destroy(gameObject);
        }
        dragging = false;
        line1.enabled = false;
        line2.enabled = false;
        manager.board.Unlight();
    }

    private void OnDrag(PointerEventData eventData) {
        line1.SetPosition(1, Utils.GetGroundIntersect(cam.ScreenPointToRay(eventData.position), 1f));
        line2.SetPosition(1, Utils.GetGroundIntersect(cam.ScreenPointToRay(eventData.position), 1f));
    }
}
