using UnityEngine;
using System.Collections;
using System;
using UnityEngine.EventSystems;

namespace Assets.Scripts.UI
{
    public class NavigationController : MonoBehaviour
    {
        public SlideScreen homeScreen;
        private SlideScreen current;

        // private CameraSlider cameraSlider;

        public void Start()
        {
            this.current = this.homeScreen;
            // this.cameraSlider = Camera.main.GetComponent<CameraSlider>();

            // this.current.slideAnimator.Play("SlideIn" + this.current.slideInDirection);
        }

        public void Slide(SlideScreen next)
        {
            this.current.slideAnimator.Play("SlideOut" + next.slideInDirection);
            next.slideAnimator.Play("SlideIn" + next.slideInDirection);

            this.current.slideInDirection = ~next.slideInDirection;
            // SlideCamera();

            this.current = next;
        }

        public void PlaySurvival()
        {
            Application.LoadLevel("Survival Level");
        }

        //private void SlideCamera()
        //{
        //    StartCoroutine(this.cameraSlider.Slide(this.current.slideInDirection));
        //}
    }
}