using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using m039.Common;
using System.Linq;

public class NumberPostOrbit : BaseOrbit
{
    // 1 4 2 3
    public NumberPost[] numberPosts;

    public Door door;

    public override bool IsEmpty => numberPosts.Length == 0;

    public AudioClip wrongSequenceSound;

    int _checkNumber;

    void Awake()
    {
        if (Application.isPlaying)
        {
            door.SetVisibility(false);
        }
    }

    public override void OnObjectPicked(PlayerBehaviour player, BaseOrbitObject orbitObject)
    {
        // If picked collectable

        if (orbitObject is NumberPost numberPost)
        {
            if (_checkNumber == numberPost.number)
            {
                // Right number.

                GameScene.Instance.Play(numberPost.pickSound);
                numberPost.SetVisibility(false);
                _checkNumber++;
            } else
            {
                // Wrong number.

                GameScene.Instance.Play(wrongSequenceSound);
                numberPosts.ForEach((c) => c.SetVisibility(true));
                _checkNumber = 1;
            }

            // Picked all object in the right order.

            if (_checkNumber > numberPosts.Length)
            {
                SetLineRenderWithCompletedColor();

                GameScene.Instance.ShowNextOrbit();
                if (door != null)
                {
                    door.SetVisibility(true);
                }
            }
        }

        // If door picked
        if (orbitObject is Door)
        {
            HideFromPlayer();
            GameScene.Instance.SelectNextOrbit();
        }
    }

    public override void HideFromPlayer()
    {
        base.HideFromPlayer();

        numberPosts.ForEach((c) => c.SetVisibility(false));
        door.SetVisibility(false);
        SetVisibility(false);
    }

    public override void ShowToPlayer(bool inactive)
    {
        base.ShowToPlayer(inactive);

        SetVisibility(true);
        numberPosts.ForEach((c) => c.SetVisibility(true));

        if (numberPosts.Length == 0)
        {
            if (inactive)
            {
                SetLineRenderWithInactiveColor();
            }
            else
            {
                SetLineRenderWithCompletedColor();
            }

            GameScene.Instance.ShowNextOrbit();
            door.SetVisibility(true);
        }
        else
        {
            door.SetVisibility(false);
        }

        _checkNumber = 1;
    }
}
