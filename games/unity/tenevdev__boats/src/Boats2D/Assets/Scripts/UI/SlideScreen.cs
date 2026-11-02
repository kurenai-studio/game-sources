using UnityEngine;
using System.Collections;
using UnityEngine.EventSystems;
using System;

namespace Assets.Scripts.UI
{
    public class SlideScreen : MonoBehaviour
    {
        public SlideDirection slideInDirection;
        public bool isHomeScreen = false;
        public Animator slideAnimator;

        public void Awake()
        {
            if (!this.isHomeScreen)
            {
                this.slideAnimator.CrossFade("SlideOut" + ~this.slideInDirection, 0, 0, 1);
                // this.slideAnimator.Play("SlideOut" + ~this.slideInDirection);
            }
        }
    }

    public enum SlideDirection
    {
        Left = 0,
        Up = 1,
        Right = ~Left,
        Down = ~Up
    }
}