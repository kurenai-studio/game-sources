using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public static class Utils
{

    public enum Axis {
        Horizontal,
        Vertical
    }

    public enum Direction {
        UpRight,
        Right,
        DownRight,
        Down,
        DownLeft,
        Left,
        UpLeft,
        Up,
    }

    public enum SpellName {
        Fireball,
        Icebolt,
        Blink,
        Polymorph
    }

    public static bool IsLayerInLayerMask(int layer, LayerMask mask) {
        return mask == (mask | (1 << layer));
    }

    public static List<RaycastHit2D> LinecastAlongLine(
        Vector2 start,
        Vector2 end,
        Vector2 direction,
        float length,
        int rayCount,
        LayerMask layers,
        Axis axis,
        Color color,
        float duration = 0,
        bool debug = false
    )
    {
        List<RaycastHit2D> none = new List<RaycastHit2D>();

        if ( length == 0 ) {
            return none;
        }

        foreach (int rayIndex in Enumerable.Range(0, rayCount + 1)) {
            var lineStart = axis == Axis.Horizontal
                ? new Vector2(
                    start.x,
                    start.y + (( end.y - start.y ) / rayCount) * rayIndex
                )
                : new Vector2(
                    start.x + (( end.x - start.x ) / rayCount) * rayIndex,
                    start.y
                );
            var lineEnd = lineStart + direction * length;

            if (debug) {
                Debug.DrawLine(start, end, Color.white, duration);
                Debug.DrawLine(lineStart, lineEnd, color, duration); 
            }
            RaycastHit2D hit = Physics2D.Linecast(lineStart, lineEnd, layers.value);

            if (hit.collider != null) {
                return new List<RaycastHit2D>() { hit };
            }
        }

        return none;
    }

    /*
     * This whole thing exists only because I didn't quite understand Unity's collision detection.
     * The same effect I was going for here could basically be had by using Rigidbodies and setting their
     * collision detection properly to Continuous or similar.
     */
    public static List<RaycastHit2D> Move(GameObject objectToMove, float moveSpeed, LayerMask wallLayers, Vector2 move)
    {
        Vector2 oldPos = objectToMove.transform.position;
        BoxCollider2D boxCollider = objectToMove.GetComponent<BoxCollider2D>();
        move.Normalize();
        Vector2 normalized = move * moveSpeed * Time.deltaTime;
        float horizontal = normalized.x;
        float vertical = normalized.y;
        Vector2 newPos = (Vector2)oldPos + normalized;

        List<RaycastHit2D> horHits = new List<RaycastHit2D>();
        if (horizontal > 0) {
            horHits = Utils.LinecastAlongLine(
                new Vector2(boxCollider.bounds.max.x, boxCollider.bounds.min.y),
                new Vector2(boxCollider.bounds.max.x, boxCollider.bounds.max.y),
                Vector2.right,
                Mathf.Abs(horizontal),
                4,
                wallLayers,
                Utils.Axis.Horizontal,
                Color.magenta,
                1
            );
        } else if (horizontal < 0) {
            horHits = Utils.LinecastAlongLine(
                new Vector2(boxCollider.bounds.min.x, boxCollider.bounds.min.y),
                new Vector2(boxCollider.bounds.min.x, boxCollider.bounds.max.y),
                Vector2.left,
                Mathf.Abs(horizontal),
                4,
                wallLayers,
                Utils.Axis.Horizontal,
                Color.magenta,
                1
            );
        }

        if (horHits.Count > 0) {
            Vector2 horHitPos = horHits[0].point;
            newPos.x = horHitPos.x < oldPos.x
                ? horHitPos.x + boxCollider.bounds.extents.x + 1
                : horHitPos.x - boxCollider.bounds.extents.x - 1;
        }

        List<RaycastHit2D> verHits = new List<RaycastHit2D>();
        if (vertical > 0) {
            verHits = Utils.LinecastAlongLine(
                new Vector2(boxCollider.bounds.min.x, boxCollider.bounds.max.y),
                new Vector2(boxCollider.bounds.max.x, boxCollider.bounds.max.y),
                Vector2.up,
                Mathf.Abs(vertical),
                4,
                wallLayers,
                Utils.Axis.Vertical,
                Color.magenta,
                1,
                true
            );
        } else if (vertical < 0) {
            verHits = Utils.LinecastAlongLine(
                new Vector2(boxCollider.bounds.min.x, boxCollider.bounds.min.y),
                new Vector2(boxCollider.bounds.max.x, boxCollider.bounds.min.y),
                Vector2.down,
                Mathf.Abs(vertical),
                4,
                wallLayers,
                Utils.Axis.Vertical,
                Color.magenta,
                1,
                true
            );
        }
        
        if (verHits.Count > 0) {
            Vector2 verHitPos = verHits[0].point;
            newPos.y = verHitPos.y < oldPos.y
                ? verHitPos.y + boxCollider.bounds.extents.y + 3
                : verHitPos.y - boxCollider.bounds.extents.y + 2;
        }

        if (!( verHits.Count > 0 && horHits.Count > 0 )) {
            if (verHits.Count > 0) {
                if ( horizontal == 0 ) {
                    return verHits;
                } else {
                    newPos = new Vector2(oldPos.x + horizontal, oldPos.y);
                }
            }
            if ( horHits.Count > 0 ) {
                if ( vertical == 0 ) {
                    return horHits;
                } else {
                    newPos = new Vector2(oldPos.x, oldPos.y + vertical);
                }
            }
        } else {
            return horHits.Concat(verHits).ToList();
        }

        objectToMove.transform.position = newPos;
        return horHits.Concat(verHits).ToList();
    }

    public static void DrawCrossOnPoint(Vector2 point, float size, Color color, float duration = 0) {
        Debug.DrawLine(
            new Vector2(point.x - size, point.y - size),
            new Vector2(point.x + size, point.y + size),
            color,
            duration
        );
        Debug.DrawLine(
            new Vector2(point.x - size, point.y + size),
            new Vector2(point.x + size, point.y - size),
            color,
            duration
        );
    }
}
