using System;
using MonoLudo.Core;
using MonoLudo.Shared.Actions;
using MonoLudo.Shared.Scenes.Game;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Desktop;


namespace MonoLudo.Desktop;

public static class InputHandler
{
    /*
    //public static void ProcessInput(MonoLudo.Shared.Scenes.Game.Game game)
    public static void ProcessInput()
    {
        // Обработка клика по кубику
        if (Input.IsLeftButtonReleased())
        {
            Point mousePos = Input.GetMousePosition();
            Rectangle diceBounds = Config.GetDiceBounds();
            Console.WriteLine(mousePos);
            // Бросаем кубик
            //if (ShapeHelper.CheckCollisionPointRec(mousePos, diceBounds))
            //{
            //    GameManager.Dice.Roll();
            //}
        }

        short chKey = (short)Input.GetCharPressed();
        if (chKey != 0 && chKey >= 49 && chKey <= 54)
        {
            Console.WriteLine(chKey - 48);
            Dice.Cheat((short)(chKey - 48));
            if (MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex] != null)
            {
                MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CurrentState = Player.State.AwaitToPlayerMove;
            }
        }


        var keyPressed = Input.GetKeyPressed();
        switch (keyPressed)
        {
            case 0:
            break;
            case Keys.End:
                MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CurrentState = Player.State.AwaitToPlayerMove;
                MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CheatsTokensToPreHome();
                break;
            case Keys.Home:
                Console.WriteLine("End game");
                MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CurrentState = Player.State.AwaitToPlayerMove;
                MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CheatsTokensToHome();
            break;
            
        }
    }

    public static Tile PlayerMoveHandler(SelectObjectAction.Object needSelectTo)
    {
        if (Input.IsLeftButtonReleased())
        {
            Point mousePos = Input.GetMousePosition();
            foreach (var tile in Board.Tiles)
            {
                if (tile.Value != null)
                {
                    if (Shape.CheckCollisionPointRec(mousePos, tile.Value.GetRectangle()))
                    {
                        if (needSelectTo.Player?.ColorName == tile.Value.Color || tile.Value.Color == Config.ColorIndex.Neutral)
                        {
                            return tile.Value ?? new Tile();
                        }
                    }
                }
            }
        }
        return null;
    }

    public static bool PlayerClickBaseTokensHandler(Player player)
    {
        if (Input.IsLeftButtonReleased())
        {
            for (int i = 0; i < Config.TokensPerPlayer; i++)
            {
                Point mousePos = Input.GetMousePosition();
                var basePos = Board.GetTokenStartPosition((Board.TokenBasePositionName)i, (Config.ColorIndex)player.Id);
                if (Shape.CheckCollisionPointRec(mousePos, new Rectangle((int)basePos.X, (int)basePos.Y, Config.CellSize.X, Config.CellSize.Y)))
                {
                    Console.WriteLine(mousePos);
                    return true;
                }
            }
        }
        return false;
    }

    public static Vector2 GetVirtualMousePosition(Matrix scaleMatrix)
    {
        var mouseState = Mouse.GetState();
        return Vector2.Transform(
            new Vector2(mouseState.X, mouseState.Y),
            Matrix.Invert(scaleMatrix)
        );
    }
    */
}