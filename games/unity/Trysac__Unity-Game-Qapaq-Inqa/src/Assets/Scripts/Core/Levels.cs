using System.Collections.Generic;

namespace QapaqInqa.Core
{
    /// <summary>The look and the music of a level.</summary>
    public enum Theme
    {
        Valley,
        Mountain,
        Cave,
        Temple,
    }

    /// <summary>A short codex page about the Inca, shown before a level.</summary>
    public readonly struct Lore
    {
        public Lore(string title, string text)
        {
            Title = title;
            Text = text;
        }

        public string Title { get; }
        public string Text { get; }
    }

    public sealed class LevelInfo
    {
        public LevelInfo(string name, string trial, Theme theme, float parSeconds, Lore lore, IReadOnlyList<string> map)
        {
            Name = name;
            Trial = trial;
            Theme = theme;
            ParSeconds = parSeconds;
            Lore = lore;
            Map = map;
        }

        public string Name { get; }
        /// <summary>Which of Inti's trials the level stands for.</summary>
        public string Trial { get; }
        public Theme Theme { get; }
        /// <summary>Clearing faster than this earns a time bonus.</summary>
        public float ParSeconds { get; }
        public Lore Lore { get; }
        public IReadOnlyList<string> Map { get; }
    }

    /// <summary>
    /// The four trials of Inti. The codex pages are an English rendering of the notes that came
    /// with the original game (Game_Plot-Spanish.txt), split into short pages.
    /// </summary>
    public static class Levels
    {
        public const string Title = "Qapaq Inqa";
        public const string Subtitle = "The Trials of Inti";

        public static readonly Lore Prologue = new Lore(
            "Choosing the Inca",
            "The chronicles describe the Inca as a supreme ruler, much like the kings of medieval Europe. " +
            "Yet the office did not simply pass to the eldest son: the gods chose. A candidate faced rigorous " +
            "trials of physical and moral aptitude, wrapped in a complex ritual through which the sun god Inti " +
            "named who should become Inca. If Inti agreed, he gave the future Inca the power of rain.");

        public static readonly Lore Epilogue = new Lore(
            "After the Last Inca",
            "The last Inca to govern was Atahualpa. Afterwards the title was carried by the leaders of the " +
            "resistance against the conquest of Tawantinsuyu, such as Manco Inca and Túpac Amaru I, " +
            "remembered as the Incas of Vilcabamba.");

        // Legend: # stone, = ledge, H ladder, ^ spikes, P start, E Sun Gate, o coin, A golden idol,
        // S mullu shell, + heart, C checkpoint, w stone warrior, b bat, B Stone Puma.
        static readonly string[] Map1 =
        {
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "                                          A o o",
            "                                        H######      ooo   A",
            "                             ooo        H######                                S",
            "                                        H######           ====                ===",
            "                   o o o          C     H######      ===       ===       o o                  +",
            "                            ################### ===                      ====",
            "      o o o            w    ###################                       C    w          w          E",
            "                  #############################                    ################H####################",
            "   P           ################################^^^^^^^^^^^^^^^^^^^^################H         ###########",
            "###################################################################################H   A o o ###########",
            "########################################################################################################",
        };

        static readonly string[] Map2 =
        {
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "                                              A",
            "                                             ===              b",
            "                                                   o o              ooo                                       b",
            "                                          ===                                                           S           +",
            "                                            C         w     ====                                       ===",
            "                                o o o   H################          ##########H             b             A   =====     E",
            "                                        H################          ##########H                          #####     ##########",
            "               b                        H################          ##########H ===== =====   o o        #####     ##########",
            "     o o o                     ##########################          ##########H                   ############     ##########",
            "                           ====##########################          ##########H     A         === ############     ##########",
            "  P                    w       ##########################          ##########H  ^^^   ^^^w  C    ############     ##########",
            "###########========######################################          ##########################################     ##########",
            "###########        ######################################          ##########################################     ##########",
            "###########        ######################################          ##########################################     ##########",
        };

        static readonly string[] Map3 =
        {
            "####################################################################################################################",
            "####################################################################################################################",
            "####################################################################################################################",
            "######################################                                 #############################################",
            "######################################                    b            ########################                    #",
            "###################################### H          o o o                ########################                    #",
            "###################################### H                               ########################       b            #",
            "###################################### H      w                 A      ########################                    #",
            "###################################### H==#########################    ########################           A        #",
            "###################################### H  #########################    ########################  o o    =====      #",
            "###################################### H  #########################                        ####H======             #",
            "#                                      H ##########################                        ####H                   #",
            "#                                      H #                                                     H                   #",
            "#                                      H #              b                    o                 H                   #",
            "#                                      H #   A                              ===       S        H                   #",
            "#      o o o           ====            H # ======                      ===           ===       H                   #",
            "#  P           w       ^^^^       C    H #  ^^^^    w     o o C          ^^^^^^    w           H    w        + E   #",
            "####################################################################################################################",
            "####################################################################################################################",
            "####################################################################################################################",
        };

        static readonly string[] Map4 =
        {
            "################################################################################################",
            "################################################################################################",
            "################################################################################################",
            "                                              #",
            "                                              #",
            "                                              #",
            "                                              #",
            "                                              #",
            "                A                             #                   S",
            "                       b                      #                  ====",
            "                         o o        A                      o o o",
            "               ####====        ==  ===   +                 =====",
            "     o o o     ####        w          w              o o                  o o",
            "           ########    ########   #######            ====                 ====",
            "  P        ########^^^^########^^^#######  C                                    B         E",
            "################################################################################################",
            "################################################################################################",
            "################################################################################################",
        };

        public static readonly IReadOnlyList<LevelInfo> All = new[]
        {
            new LevelInfo("The Sacred Valley", "The Trial of the Body", Theme.Valley, 95f,
                new Lore("Sapa Inca",
                    "In Quechua, Sapa Inqa means \"the Inca, the only one\". The ruler was also called " +
                    "Qapaq Inqa, \"the mighty Inca\", in classical Quechua."),
                Map1),
            new LevelInfo("The Qhapaq Ñan", "The Trial of the Road", Theme.Mountain, 120f,
                new Lore("Inca Roca",
                    "The first sinchi (war leader) of Cusco to use the title Sapa Inca was Inca Roca, " +
                    "founder of the Hanan Cusco dynasty."),
                Map2),
            new LevelInfo("The Caves of Pacaritambo", "The Trial of the Dark", Theme.Cave, 130f,
                new Lore("Cusco and Manco Cápac",
                    "Cusco was the centre of the empire and the residence of the Incas. Inca society held " +
                    "that its rulers descended from Manco Cápac, the mythical founder and cultural hero who " +
                    "brought civilised life, and on him rested the legitimacy of Inca rule."),
                Map3),
            new LevelInfo("The Gate of Inti", "The Trial of Courage", Theme.Temple, 110f,
                new Lore("The Final Trial",
                    "Inti names who shall rule. Recover the last golden idols, face the Stone Puma that " +
                    "guards the Sun Gate, and step into the light."),
                Map4),
        };
    }
}
