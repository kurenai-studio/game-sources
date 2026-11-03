using System;
using System.Collections.Generic;

namespace QapaqInqa.Core
{
    public enum RunPhase
    {
        Playing,
        /// <summary>A level was cleared; the results card waits for <see cref="Run.Continue"/>.</summary>
        LevelComplete,
        GameOver,
        /// <summary>The last level was cleared: the trials are passed.</summary>
        Victory,
    }

    /// <summary>What a level clear earned, for the results card.</summary>
    public readonly struct LevelResult
    {
        public LevelResult(int level, float time, int levelPoints, int timeBonus, bool newBestTime, bool extraLife)
        {
            Level = level;
            Time = time;
            LevelPoints = levelPoints;
            TimeBonus = timeBonus;
            NewBestTime = newBestTime;
            ExtraLife = extraLife;
        }

        public int Level { get; }
        public float Time { get; }
        public int LevelPoints { get; }
        public int TimeBonus { get; }
        public bool NewBestTime { get; }
        public bool ExtraLife { get; }
    }

    /// <summary>
    /// A play-through: lives, score and the level sequence. A run started from the first level is a
    /// campaign and its score and total time count for the records; a run started from the level
    /// select only records level times. Clearing a level grants a life (as the original game did)
    /// and a bonus for every second under the level's par time.
    /// </summary>
    public sealed class Run
    {
        readonly Records records;
        int bankedScore;

        public Run(Records records, int firstLevel = 0) : this(records, Levels.All, firstLevel) { }

        /// <summary>A run over any list of levels (tests use small ones).</summary>
        public Run(Records records, IReadOnlyList<LevelInfo> levels, int firstLevel = 0)
        {
            LevelList = levels ?? throw new ArgumentNullException(nameof(levels));
            if (firstLevel < 0 || firstLevel >= levels.Count) throw new ArgumentOutOfRangeException(nameof(firstLevel));
            this.records = records ?? throw new ArgumentNullException(nameof(records));
            Lives = Tuning.StartingLives;
            IsCampaign = firstLevel == 0;
            Load(firstLevel);
        }

        public int LevelIndex { get; private set; }
        public IReadOnlyList<LevelInfo> LevelList { get; }
        public LevelInfo Level => LevelList[LevelIndex];
        public Stage Stage { get; private set; }
        public RunPhase Phase { get; private set; }
        public int Lives { get; private set; }
        public bool IsCampaign { get; }
        /// <summary>Banked points from earlier levels plus what the current level has earned so far.</summary>
        public int Score => bankedScore + (Phase == RunPhase.Playing ? Stage.Points : 0);
        public float TotalTime { get; private set; }
        public LevelResult LastResult { get; private set; }
        public bool NewBestScore { get; private set; }
        public bool NewBestRunTime { get; private set; }
        public int LifeBonus { get; private set; }

        public void Tick(InputFrame input, float dt)
        {
            if (Phase != RunPhase.Playing) return;
            Stage.Step(input, dt);
            if (Stage.Phase == StagePhase.Dying && Stage.PhaseTime >= Tuning.DyingTime)
            {
                LoseLife();
            }
            else if (Stage.Phase == StagePhase.Cleared)
            {
                CompleteLevel();
            }
        }

        /// <summary>From the level results: on to the next level (or the victory screen after the last).</summary>
        public void Continue()
        {
            if (Phase != RunPhase.LevelComplete) return;
            Load(LevelIndex + 1);
        }

        /// <summary>Restarts the current level from its start, keeping the score banked before it. Costs nothing, but is ignored during the death beat so it cannot dodge a lost life.</summary>
        public void RestartLevel()
        {
            if (Phase != RunPhase.Playing || Stage.Phase == StagePhase.Dying) return;
            Load(LevelIndex);
        }

        void Load(int index)
        {
            LevelIndex = index;
            Stage = new Stage(new LevelMap(LevelList[index].Map));
            Phase = RunPhase.Playing;
        }

        void LoseLife()
        {
            Lives--;
            if (Lives > 0)
            {
                Stage.Respawn();
                return;
            }
            bankedScore += Stage.Points;
            Phase = RunPhase.GameOver;
            if (IsCampaign) NewBestScore = records.SubmitScore(bankedScore);
        }

        void CompleteLevel()
        {
            float time = Stage.Elapsed;
            int bonus = Math.Max(0, (int)Math.Floor(Level.ParSeconds - time)) * Tuning.TimeBonusPerSecond;
            bool newBestTime = records.SubmitClear(LevelIndex, time);
            bankedScore += Stage.Points + bonus;
            TotalTime += time;
            bool last = LevelIndex == LevelList.Count - 1;
            bool extraLife = !last && Lives < Tuning.MaxLives;
            if (extraLife) Lives++;
            LastResult = new LevelResult(LevelIndex, time, Stage.Points, bonus, newBestTime, extraLife);
            if (!last)
            {
                Phase = RunPhase.LevelComplete;
                return;
            }
            LifeBonus = Lives * Tuning.LifeBonus;
            bankedScore += LifeBonus;
            Phase = RunPhase.Victory;
            if (IsCampaign)
            {
                NewBestScore = records.SubmitScore(bankedScore);
                NewBestRunTime = records.SubmitRunTime(TotalTime);
            }
        }
    }
}
