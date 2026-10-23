using System.Collections.Generic;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;

namespace Core;

public enum Sounds
{
    ClearMatch,
    Enter,
    MovePiece,
    PlacePiece,
    Rotate,
    Select,
    Fall,
    Hold,
}

public static class SoundManager
{
    private static Dictionary<Sounds, SoundEffect> sounds = new();

    public static void Load(ContentManager content)
    {
        sounds = new Dictionary<Sounds, SoundEffect>()
        {
            { Sounds.ClearMatch, content.Load<SoundEffect>("Sounds/ClearMatch") },
            { Sounds.Enter, content.Load<SoundEffect>("Sounds/Enter") },
            { Sounds.MovePiece, content.Load<SoundEffect>("Sounds/MovePiece") },
            { Sounds.PlacePiece, content.Load<SoundEffect>("Sounds/PlacePiece") },
            { Sounds.Rotate, content.Load<SoundEffect>("Sounds/Rotate") },
            { Sounds.Select, content.Load<SoundEffect>("Sounds/Select") },
            { Sounds.Fall, content.Load<SoundEffect>("Sounds/Fall") },
            { Sounds.Hold, content.Load<SoundEffect>("Sounds/Hold") },
        };
    }

    public static void Play(Sounds sound)
    {
        sounds[sound].Play();
    }
}