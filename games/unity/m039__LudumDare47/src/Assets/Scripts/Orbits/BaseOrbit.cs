using m039.Common;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class BaseOrbit : MonoBehaviour
{
    public enum OrbitDirection
    {
        CCW, // Counter clock wise - default
        CW // Clock wise
    }

    public OrbitDirection orbitDirection = OrbitDirection.CCW;

    public float radius = 10f;

    public float offsetRadius = 2f;

    public float lineWidth = 2f;

    public float blockInputTimeWhenEntered = 0.5f;

    public Color lineColor = Color.grey.WithAlpha(0.4f);

    public Color lineColorInactive = Color.grey.WithAlpha(0.1f);

    public Color lineColorCompleted = Color.blue.WithAlpha(0.1f);

    public int lineSegments = 32;

    public LineRenderer lineRenderer;

    public StartLocation startLocation;

    public bool isCheckpoint = false;

    bool _visibility = true;

    public virtual bool IsEmpty => true;

    public bool VisibileToPlayer { get; set; } = false;

    protected virtual void OnEnable()
    {
        UpdateLineRenderer();
    }

    protected virtual void OnValidate()
    {
        UpdateLineRenderer();
    }

    public Vector3 GetPositionAlognOrbit(float angle, float positionOffsetX, float positionOffsetY)
    {
        return GetPositionAlognOrbit(angle, new Vector2(positionOffsetX, positionOffsetY));
    }

    public Vector3 GetPositionAlognOrbit(float angle, Vector2 positionOffset)
    {
        positionOffset.x = Mathf.Clamp(positionOffset.x, -1, 1);
        positionOffset.y = Mathf.Clamp(positionOffset.y, -1, 1);

        if (positionOffset.magnitude > 1)
        {
            positionOffset.Normalize();
        }

        var direction = Quaternion.Euler(0, -angle, 0) * Vector3.forward;

        var offset = Vector3.zero;

        offset += positionOffset.x * direction * offsetRadius;
        offset += positionOffset.y * Vector3.up * offsetRadius;

        return transform.position + direction * radius + offset;
    }

    void UpdateLineRenderer()
    {
        if (lineRenderer != null)
        {
            SetLineRenderWithNormalColor();

            lineRenderer.positionCount = lineSegments;

            lineRenderer.loop = true;

            lineRenderer.startWidth = lineWidth;
            lineRenderer.endWidth = lineWidth;

            for (int i = 0; i < lineSegments; i++)
            {
                var angle = i * 2 * Mathf.PI / lineSegments * Mathf.Rad2Deg;
                lineRenderer.SetPosition(i, Quaternion.Euler(0, angle, 0) * Vector3.forward * radius);
            }
        }
    }

    public void PickObject(PlayerBehaviour player, BaseOrbitObject orbitObject)
    {
        if (orbitObject == null)
            return;

        OnObjectPicked(player, orbitObject);
    }

    public virtual void OnObjectPicked(PlayerBehaviour player, BaseOrbitObject orbitObject)
    {
        GameScene.Instance.Play(orbitObject.pickSound);
    }

    public bool GetVisibility()
    {
        return _visibility;
    }

    public virtual void SetVisibility(bool visibility)
    {
        if (lineRenderer != null)
        {
            lineRenderer.gameObject.SetActive(visibility);
        }
        _visibility = visibility;
    }

    protected void SetLineRenderWithNormalColor()
    {
        lineRenderer.startColor = lineColor;
        lineRenderer.endColor = lineColor;
    }

    protected void SetLineRenderWithInactiveColor()
    {
        lineRenderer.startColor = lineColorInactive;
        lineRenderer.endColor = lineColorInactive;
    }

    protected void SetLineRenderWithCompletedColor()
    {
        lineRenderer.startColor = lineColorCompleted;
        lineRenderer.endColor = lineColorCompleted;
    }

    public virtual void HideFromPlayer()
    {
        VisibileToPlayer = false;
    }

    public virtual void ShowToPlayer(bool inactive)
    {
        VisibileToPlayer = true; 

        if (inactive)
        {
            SetLineRenderWithInactiveColor();
        } else
        {
            SetLineRenderWithNormalColor();
        }
    }

    protected virtual void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, radius);

        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(transform.position + Vector3.forward * radius, offsetRadius);
    }
}
