using Assets.Scripts.UI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEngine.UI;

namespace Assets.Scripts.Game.Components
{
    public class SurvivalManager : LevelManagerBase
    {
        private int highScore;
        public Text highScoreLabel;

        public void Awake()
        {
            this.highScore = PlayerPrefs.GetInt("HighScore", 0);
            GameObject.Find("Last High Score").GetComponent<Number>().value = this.highScore;
            this.highScoreLabel.text = this.highScore.ToString();
        }
        public override void Start()
        {
            base.Start();

            this.failedTitle = "GAME OVER";
        }

        public override void Play()
        {
            switch (this.state)
            {
                case LevelState.Failed:
                    this.Restart();
                    break;
                case LevelState.InProgress:
                    // Resume game
                    this.panel.ToggleTime();
                    this.panelAnimator.Play("SlideUp");
                    break;
                default:
                    break;
            }
        }

        public override void IncrementScore()
        {
            base.IncrementScore();
            if (this.score > this.highScore)
            {
                this.highScore = this.score;
                this.highScoreLabel.text = this.highScore.ToString();
                PlayerPrefs.SetInt("HighScore", this.highScore);
            }
        }
    }
}
