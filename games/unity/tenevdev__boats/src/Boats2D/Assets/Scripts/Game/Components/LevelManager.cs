using Assets.Scripts.UI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEngine.UI;

namespace Assets.Scripts.Game.Components
{
    public class LevelManager : LevelManagerBase
    {
        public int levelNumber;
        public int objective;

        public void Awake()
        {
            GameObject.Find("Objective").GetComponent<Number>().value = this.objective;
        }

        public override void Start()
        {
            base.Start();

            this.LevelComplete += this.Complete;
            this.failedTitle = "LEVEL FAILED";
        }

        public override void Play()
        {
            switch (this.state)
            {
                case LevelState.Complete:
                    // Play next level
                    this.panel.ToggleTime();
                    Application.LoadLevel(this.levelNumber + 1);
                    break;
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

        private void Complete(object sender, EventArgs e)
        {
            PlayerPrefs.SetInt("LastLevel", this.levelNumber);

            this.Pause("LEVEL COMPLETE");
            this.state = LevelState.Complete;
        }

        public override void IncrementScore()
        {
            base.IncrementScore();
            if (this.score == this.objective)
            {
                this.OnLevelComplete();
            }
        }

        public event EventHandler LevelComplete;
        protected void OnLevelComplete()
        {
            if (this.LevelComplete != null)
            {
                this.LevelComplete(this, new EventArgs());
            }
        }
    }
}
