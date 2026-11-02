using Assets.Scripts.Game.Components;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.UI
{
    public class ScoreBoard : MonoBehaviour
    {
        private List<DigitTile> scoreTiles;

        public DigitTile scoreTile;

        public void Start()
        {
            this.scoreTiles = new List<DigitTile>();

            DigitTile tile = Instantiate<DigitTile>(this.scoreTile);
            tile.transform.SetParent(this.transform, false);

            this.scoreTiles.Add(tile);

            LevelManagerBase.Instance.ScoreChanged += this.Increment;
        }

        public void Increment(object level, EventArgs args)
        {
            int index = 0;

            do
            {
                // If there is an overflow add another tile to the front
                if (index == this.scoreTiles.Count)
                {
                    this.AddTile();
                }

                this.scoreTiles[index].Increase();

            } while (this.scoreTiles[index++].Current == 0);

        }

        private void AddTile()
        {
            DigitTile tile = Instantiate<DigitTile>(this.scoreTile);
            tile.transform.SetParent(this.transform, false);

            tile.transform.Translate(new Vector3(-5 * this.scoreTiles.Count, 0, 0));

            this.scoreTiles.Add(tile);
        }
    }
}
