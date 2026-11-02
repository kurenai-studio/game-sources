using Assets.Scripts.Game.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class HitPointsBar : MonoBehaviour
    {
        private SpriteRenderer barRenderer;

        public void Start()
        {
            this.barRenderer = this.GetComponent<SpriteRenderer>();
        }

        public void UpdateBar(Hittable sender, HitEventArgs args)
        {
            this.barRenderer.color = Color.Lerp(Color.red, Color.green, args.HitPointsPercent);
            this.transform.localScale = new Vector3(args.HitPointsPercent, 1, 1);
        }
    }
}
