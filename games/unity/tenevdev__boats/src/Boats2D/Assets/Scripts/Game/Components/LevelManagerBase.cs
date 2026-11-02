using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEngine.UI;

namespace Assets.Scripts.Game.Components
{
    public abstract class LevelManagerBase : MonoBehaviour
    {
        protected static LevelManagerBase instance;
        public static LevelManagerBase Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = GameObject.FindObjectOfType<LevelManagerBase>();
                }
                return instance;
            }
        }

        protected string failedTitle = "FAILED";

        protected int score;
        protected Animator panelAnimator;
        protected LevelState state;

        public int boatCount;
        public int passengerWaitingTime;
        public TimeController panel;
        public Text panelTitle;

        public virtual void Start()
        {
            this.score = 0;

            this.state = LevelState.InProgress;
            this.panelAnimator = this.panel.GetComponent<Animator>();
        }

        public virtual void BoatLost()
        {
            this.boatCount -= 1;
            if (this.boatCount == 0)
            {
                this.state = LevelState.Failed;
                this.Pause(this.failedTitle);
            }
        }

        public virtual void IncrementScore()
        {
            this.score += 1;
            OnScoreChanged();
        }

        public virtual void Restart()
        {
            this.panel.ToggleTime();
            Application.LoadLevel(Application.loadedLevel);
        }

        public virtual void Home()
        {
            this.panel.ToggleTime();
            Application.LoadLevel("Home");
        }

        public virtual void Pause(string panelTitle)
        {
            if (!this.panelTitle.IsDestroyed())
            {
                this.panelTitle.text = panelTitle;
                this.panelAnimator.Play("SlideDown");
            }
        }

        public abstract void Play();

        public event EventHandler ScoreChanged;
        protected void OnScoreChanged()
        {
            if (this.ScoreChanged != null)
            {
                this.ScoreChanged(this, new EventArgs());
            }
        }
    }

    public enum LevelState
    {
        InProgress = 0,
        Complete = 1,
        Failed = 2
    }
}
