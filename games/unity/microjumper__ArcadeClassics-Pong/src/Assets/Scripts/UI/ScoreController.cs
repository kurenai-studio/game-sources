using System;
using Playfield;
using UnityEngine;
using UnityEngine.UIElements;

namespace UI
{
    public class ScoreController : MonoBehaviour
    {
        [SerializeField]
        private int targetScore = 10;
        
        private Label leftScoreLabel;
        private Label rightScoreLabel;
        
        private int leftScore = 0;
        private int rightScore = 0;
    
        private void Awake()
        {
            GetReferences();
        }
    
        private void OnEnable()
        {
            GoalLine.OnGoalScored += HandleGoalScored;
        }

        private void OnDisable()
        {
            GoalLine.OnGoalScored -= HandleGoalScored;
        }

        private void GetReferences()
        {
            var root = GetComponent<UIDocument>().rootVisualElement;
            var labelContainer = root.Q<VisualElement>("label__container");

            leftScoreLabel = labelContainer.Q<Label>("left-score__label");
            rightScoreLabel = labelContainer.Q<Label>("right-score__label");
        }

        private void HandleGoalScored(Side side)
        {
            switch (side)
            {
                case Side.Left:
                    rightScore++;
                    rightScoreLabel.text = rightScore.ToString();
                    break;
                case Side.Right:
                    leftScore++;
                    leftScoreLabel.text = leftScore.ToString();   
                    break;
                default:
                    throw new ArgumentOutOfRangeException(nameof(side), side, null);
            }
            
            CheckForGameOver();
        }

        private void CheckForGameOver()
        {
            if (leftScore >= targetScore || rightScore >= targetScore)
            {
                GameManager.Instance.GameOver();
            }
        }
    }
}