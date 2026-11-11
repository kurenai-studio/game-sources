using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

public class GameState : MonoBehaviour
{
    Dictionary<string, string> StringMap;

    public HashSet<string> Unlocked = new();

    public HashSet<string> dedushkaUnlockable = new()
    {
        "lenin",
        "das kapital",
        "icon",
        "plank",
        "cellar door",
        "garage door",
        "garden gate",
    };

    public List<string> listToUnlock = new();

    void Start()
    {
        StringMap = new() {
            { "_comment", "I can't touch it" },

            { "lenin_lock", "I have to ask Dedushka if I can take it. I don't think he loves Lenin this much" },
            { "lenin_request", "Can I exterminate Lenin" },
            { "lenin_response", "Noo! It's my beloved theorist of Marxism-Leninism! Don' t you dare desecrate his portrait!" },
            { "lenin_comment", "Shoot, he does love Lenin this much" },

            // { "can_lock", "" },
            // { "detective novel_lock", "" },

            { "icon_lock", "Hm, Babushka's icon of Holy Mother. I must ask Dedushka before proceeding." },
            { "icon_request", "Hi, Dedushka! I am thinking about using Icon of Holy Mother, is this ok?" },
            { "icon_response", "Of course, Vnuchek, enjoy yourself!" },

            { "das kapital_lock", "Hmm, maybe I should ask Dedushka first..." },
            { "das kapital_request", "Can i, pretty please, take your copy of Das Kapital for a second?" },
            { "das kapital_response", "Fine! But you should read it. Marx had an outstanding view on materialism!" },

            // { "pillow", "" },

            { "plank_lock", "I think, Dedushka wanted to build something of these. I must ask first" },
            { "plank_request", "Do you still need those old planks?" },
            { "plank_response", "Of course I need them! You can play, but return them back afterwards" },

            // { "stool_lock", "" },
            // { "stump_lock", "" }

            { "cellar door_lock", "There are 100% some useful tower-things in the cellar. I must ask for permission." },
            { "cellar door_request", "Hi Ded, can I descend down to the underground?" },
            { "cellar door_response", "What for, Vnuchek? You'd better play here, on the surface" },
            { "cellar door_comment", "Well, I guess today I'm not visiting cellar" },

            { "garage door_lock", "What terrible old secrets are hidden behind this code lock? We might never know" },
            { "garage door_request", "Dedushka, what is the garage door code? I want to look inside" },
            { "garage door_response", "I'm sorry, Vnuchek, but I don't remember. We should wait for your Babushka." },
            { "garage door_comment", "All right then, keep your secrets" },

            { "garden gate_lock", "I think, I should not go OUTSIDE alone, Better check with Dedushka" },
            { "garden gate_request", "Can I go outside?" },
            { "garden gate_response", "No no no, Vnuchek, it's dangerous outside" },
            { "garden gate_comment", "It's very forbidden, apparently" },

            { "game_manager_vnuchek_start", "Ok, I can just put stool on the table and try jumping a little bit higher" },
            { "game_manager_deadushka_podval", "Vnuchok! Why did you climb so high! You shall better go play in the cellar, maybe there is something interesting there" },
            { "game_manager_brother_message", "Hi, little bro! I've sent you a funny video in the MMS. Signal in the countryside must be bad. I send you a pin code for the garage, though (it's very secret, don't tell Babushka)" },
            { "game_manager_brother_message_2", "Hahaha! Wat a funny video, isn't it? That mean you've won the game, by the way. Cool!" },
        };
    }

    public string nextThingToUnlock()
    {
        while (listToUnlock.Count != 0)
        {
            var tooltip = listToUnlock[0].ToLower();
            listToUnlock.RemoveAt(0);

            if (dedushkaUnlockable.Contains(tooltip) && !Unlocked.Contains(tooltip))
            {
                Unlocked.Add(tooltip);
                return tooltip;
            }
        }

        return null;
    }

    public string GetString(string key)
    {
        var k = key.ToLower();
        if (!StringMap.ContainsKey(k))
            return $"UNKNOWN STRING \"{key}\"";
        return StringMap[k];
    }

    public bool HasString(string key)
    {
        var k = key.ToLower();
        return StringMap.ContainsKey(k);
    }

    public bool TouchObject(string tooltip)
    {
        var t = tooltip.ToLower();
        if (Unlocked.Contains(t))
            return true;

        listToUnlock.Add(t);
        return false;
    }
}
