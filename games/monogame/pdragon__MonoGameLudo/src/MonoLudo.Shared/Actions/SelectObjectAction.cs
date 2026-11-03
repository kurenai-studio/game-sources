using System;
using System.Linq;
using MonoLudo.Core;
using MonoLudo.Desktop;
using MonoLudo.Shared.Scenes;
using MonoLudo.Shared.Scenes.Game;
//using static LudoGame.MainGameLoop.Board;
//using MonoLudo.MainGameLoop;
#if DESKTOPGL
    using MonoLudo.Desktop;
#elif __ANDROID__
    using MonoLudo.Desktop;
#endif

namespace MonoLudo.Shared.Actions
{
    public class SelectObjectAction: IGameAction
    {
        public class Object
        {
            public enum RequiredCell : short
            {
                None, // требуется плитку выбрать, вне зависимости от того что на ней
                WithToken,
                Empty,
                Base,
                Home,
                Specify
            }
            public RequiredCell Type { get; set; }
            public Player Player { get; set; }
        }
        public Object NeedSelectTo { get; private set; }
        public bool IsCompleted { get; set; }
        private Player CurrentPlayer;

        public SelectObjectAction(Player player, Object needSelectTo)
        {
            CurrentPlayer = player;
            NeedSelectTo = needSelectTo;
        }

        public void Start()
        {
            //Console.WriteLine($"Player {CurrentPlayer.Id} start moving");
        }

        public void Update()
        {

            Tile tile = Input.PlayerMoveHandler(NeedSelectTo);
            if (tile != null)
            {
                Token token = tile.GetFirstTokenOnTile(CurrentPlayer);
                Console.WriteLine($"Player clicked to tile {tile.Id}");
                if (token != null)
                {
                    var enemyTokens = Board.GetEnemyTokensOnTile(Board.CalculateDestTile(token, Dice.GetValue()), (short)token.PlayerColor);
                    //var enemyTokens = Board.GetEnemyTokensOnTile(GetTileById(CalculateDestTile(token, Dice.GetValue())), (short)token.PlayerColor);
                    //var enemyTokens = Board.GetEnemyTokensOnTile(GetTileById((short)(tile.Id + Dice.GetValue())), (short)token.PlayerColor);
                    if (token != null && enemyTokens != null && enemyTokens.Count() <= 1)
                    {
                        if (enemyTokens.Count() == 1)
                        {
                            //Program.Queue.Enqueue(new TimerAction(5f));
                            MainGameScene.Queue.Enqueue(new BackToBaseAction(enemyTokens[0]));
                            Game.SetRepeatTurnTimesLeft(Game.MAX_REPEAT_MOVES);
                        }
                        if (token.IsInHome)
                        {
                            //var lastHomeTile = HomeTiles[(short)token.PlayerColor].Last();
                            var lastHomeTile = Board.Tiles.Where(t => t.Value?.Color == token.PlayerColor).Last();
                            if (lastHomeTile.Value != null && token.Tile != null)
                            {
                                var tryMoveTo = lastHomeTile.Value.Id - (short)(token!.Tile.Id + Dice.GetValue());
                                if (tryMoveTo >= 0)
                                {
                                    token.Move(Dice.GetValue());
                                    IsCompleted = true;
                                }
                            }
                        }
                        else
                        {
                            token.Move(Dice.GetValue());
                            IsCompleted = true;
                        }
                    }
                }
            }
            if (Dice.GetValue() == 6 && Input.PlayerClickBaseTokensHandler(CurrentPlayer))
            {
                var token = CurrentPlayer.Tokens.Where(a => a.IsInBase).FirstOrDefault();
                if (token != null)
                {
                    var enemyTokens = Board.GetEnemyTokensOnTile(Board.GetTileById(Config.StartPosition[token.PlayerColor]), (short)token.PlayerColor);
                    if (enemyTokens != null && enemyTokens.Count() <= 1)
                    {
                        if (enemyTokens.Count() == 1)
                        {
                            MainGameScene.Queue.Enqueue(new BackToBaseAction(enemyTokens[0]));
                        }
                        token.Move(Dice.GetValue());
                        IsCompleted = true;
                    }
                }
            }

        }

        public void CheckForObjectPresets()
        {
            if (CurrentPlayer != null)
            {

            }
        }

        public void Complete()
        {
            CurrentPlayer.CurrentState = Player.State.EndTurn;
        }
    }
}
