using Monod.InputModule;

namespace DerelictDimension;

public static class InputActions
{
    public static InputActionIndex MoveLeft;
    public static InputActionIndex MoveRight;
    public static InputActionIndex MoveUp;
    public static InputActionIndex MoveDown;
    public static InputActionIndex Kick;
    public static InputActionIndex Attack;
    public static InputActionIndex Block;

    public static void Initialize()
    {
        var info = InputActionIndex.Info;

        MoveLeft = info.AddOrGetValue("MoveLeft");
        Input.DefaultMap.Add(MoveLeft, new([new(Key.A)]));

        MoveRight = info.AddOrGetValue("MoveRight");
        Input.DefaultMap.Add(MoveRight, new([new(Key.D)]));

        MoveUp = info.AddOrGetValue("MoveUp");
        Input.DefaultMap.Add(MoveUp, new([new(Key.W)]));

        MoveDown = info.AddOrGetValue("MoveDown");
        Input.DefaultMap.Add(MoveDown, new([new(Key.S)]));

        Kick = info.AddOrGetValue("Kick");
        Input.DefaultMap.Add(Kick, new([new(Key.LeftShift)]));

        Attack = info.AddOrGetValue("Attack");
        Input.DefaultMap.Add(Attack, new([new(Key.Mouse1)]));

        Block = info.AddOrGetValue("Block");
        Input.DefaultMap.Add(Block, new([new(Key.Mouse2)]));

    }
}
