using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.UI
{
    public class Number : MonoBehaviour
    {
        public DigitTile digitTile;
        public int value;

        public void Start()
        {
            int number = this.value, digit = 0, count = (int)Math.Floor(Math.Log10(number + 1));
            while (number > 9)
            {
                digit = number % 10;

                DigitTile tile = Instantiate<DigitTile>(this.digitTile);
                tile.transform.SetParent(this.transform, false);
                tile.transform.Translate(new Vector3(5 * count--, 0, 0));

                tile.Current = digit;

                number /= 10;
            }
            // Last digit
            DigitTile lastTile = Instantiate<DigitTile>(this.digitTile);
            lastTile.transform.SetParent(this.transform, false);
            lastTile.transform.Translate(new Vector3(5 * count--, 0, 0));

            lastTile.Current = number;
        }
    }
}
