using System;
using System.Collections.Generic;
using QapaqInqa.Core;
using UnityEngine;
using UnityEngine.UIElements;

namespace QapaqInqa.Game
{
    /// <summary>One line of a menu: a label, an optional value, and what choosing or nudging it does.</summary>
    public sealed class MenuItem
    {
        public string Label;
        public Func<string> Value;
        public Action Activate;
        /// <summary>Left/right on the item (-1 or +1); null when it has no value to change.</summary>
        public Action<int> Adjust;
        public bool Enabled = true;
    }

    /// <summary>A menu or card: a title, optional text, and items chosen with keys, pad or mouse.</summary>
    public sealed class MenuPage
    {
        public string Title;
        public string Subtitle;
        public string Body;
        public string Footer;
        public bool ShowEmblem;
        public Action Back;
        public readonly List<MenuItem> Items = new List<MenuItem>();
    }

    /// <summary>
    /// The UI Toolkit overlay, built in code and styled by Assets/UI/Hud.uss: the in-play HUD,
    /// floating score text, banners and every menu. Items never take keyboard focus; the
    /// director reads the keys and moves the highlight itself.
    /// </summary>
    [RequireComponent(typeof(UIDocument))]
    public sealed class Hud : MonoBehaviour
    {
        sealed class Floater
        {
            public Label Label;
            public Vector3 World;
            public float Age;
        }

        VisualElement root;
        VisualElement play;
        VisualElement hearts;
        Label lives;
        Label score;
        Label idols;
        Label coins;
        Label timer;
        Label levelName;
        VisualElement boss;
        VisualElement bossFill;
        Label banner;
        Label bannerSub;
        VisualElement bannerBox;
        VisualElement hurt;
        VisualElement floaters;
        VisualElement menuLayer;
        VisualElement menuPanel;
        Label menuTitle;
        Label menuSubtitle;
        Label menuBody;
        VisualElement emblem;
        VisualElement menuItems;
        Label menuFooter;
        readonly List<Label> itemLabels = new List<Label>();
        readonly List<Floater> active = new List<Floater>();
        MenuPage page;
        float bannerTime;
        float hurtLevel;
        int shownHearts = -1;

        public int Selected { get; private set; }
        public MenuPage Page => page;
        public bool MenuOpen => page != null;
        /// <summary>For tests and tools: the text currently on the banner.</summary>
        public string BannerText => banner?.text;

        public void Build(Texture2D icon)
        {
            root = GetComponent<UIDocument>().rootVisualElement;
            root.Clear();
            root.AddToClassList("hud");
            root.pickingMode = PickingMode.Ignore;

            hurt = Layer("hurt");
            floaters = Layer("floaters");

            play = Layer("play");
            var left = Box(play, "corner corner--left");
            hearts = Box(left, "hearts");
            lives = Text(left, "lives", "x3");
            var center = Box(play, "corner corner--center");
            levelName = Text(center, "level-name", "");
            var counters = Box(center, "row");
            idols = Text(counters, "counter counter--idols", "0/3");
            coins = Text(counters, "counter counter--coins", "0");
            var right = Box(play, "corner corner--right");
            score = Text(right, "score", "0");
            timer = Text(right, "timer", "0:00.0");
            boss = Box(play, "boss hidden");
            Text(boss, "boss__name", "THE STONE PUMA");
            var track = Box(boss, "boss__track");
            bossFill = Box(track, "boss__fill");

            bannerBox = Box(root, "banner hidden");
            banner = Text(bannerBox, "banner__title", "");
            bannerSub = Text(bannerBox, "banner__sub", "");

            menuLayer = Layer("menu-layer hidden");
            menuLayer.pickingMode = PickingMode.Position;
            menuPanel = Box(menuLayer, "menu");
            emblem = Box(menuPanel, "emblem");
            emblem.style.backgroundImage = new StyleBackground(icon);
            menuTitle = Text(menuPanel, "menu__title", "");
            menuSubtitle = Text(menuPanel, "menu__subtitle", "");
            menuBody = Text(menuPanel, "menu__body", "");
            menuItems = Box(menuPanel, "menu__items");
            menuFooter = Text(menuPanel, "menu__footer", "");
        }

        // ---- Play HUD ----

        public void ShowPlay(bool visible) => play.EnableInClassList("hidden", !visible);

        public void UpdatePlay(Run run, bool showTimer, Camera camera)
        {
            Stage stage = run.Stage;
            if (shownHearts != stage.Health.Hearts + stage.Health.Max * 10)
            {
                shownHearts = stage.Health.Hearts + stage.Health.Max * 10;
                hearts.Clear();
                for (int i = 0; i < stage.Health.Max; i++)
                {
                    Box(hearts, i < stage.Health.Hearts ? "heart" : "heart heart--empty");
                }
            }
            lives.text = "LIVES " + run.Lives;
            score.text = run.Score.ToString("N0");
            idols.text = $"IDOLS {stage.ArtifactsFound}/{stage.ArtifactsTotal}";
            idols.EnableInClassList("counter--done", stage.GateOpen);
            coins.text = "GOLD " + stage.CoinsFound;
            timer.text = Records.FormatTime(Mathf.Max(0.01f, stage.Elapsed));
            timer.EnableInClassList("hidden", !showTimer);
            levelName.text = run.Level.Name.ToUpperInvariant();
            StonePuma puma = stage.Boss;
            bool fight = puma != null && puma.Move != BossMove.Dormant && puma.Alive;
            boss.EnableInClassList("hidden", !fight);
            if (fight) bossFill.style.width = Length.Percent(100f * puma.HealthLeft / puma.MaxHealth);
        }

        public void Hurt() => hurtLevel = 1f;

        public void Banner(string title, string sub, float seconds = 1.8f)
        {
            banner.text = title;
            bannerSub.text = sub ?? "";
            bannerSub.EnableInClassList("hidden", string.IsNullOrEmpty(sub));
            bannerBox.RemoveFromClassList("hidden");
            bannerTime = seconds;
        }

        public void HideBanner()
        {
            bannerTime = 0f;
            bannerBox.AddToClassList("hidden");
        }

        public void Float(Vector3 world, string text, string style)
        {
            var label = new Label(text);
            label.AddToClassList("floater");
            if (!string.IsNullOrEmpty(style)) label.AddToClassList(style);
            label.pickingMode = PickingMode.Ignore;
            floaters.Add(label);
            active.Add(new Floater { Label = label, World = world });
        }

        public void ClearFloaters()
        {
            foreach (Floater f in active) f.Label.RemoveFromHierarchy();
            active.Clear();
        }

        public void Tick(float dt, Camera camera)
        {
            if (root == null) return;
            if (bannerTime > 0f)
            {
                bannerTime -= dt;
                if (bannerTime <= 0f) bannerBox.AddToClassList("hidden");
            }
            hurtLevel = Mathf.Max(0f, hurtLevel - dt * 2.5f);
            hurt.style.opacity = hurtLevel * 0.8f;
            for (int i = active.Count - 1; i >= 0; i--)
            {
                Floater f = active[i];
                f.Age += dt;
                if (f.Age > 0.9f || camera == null || root.panel == null)
                {
                    f.Label.RemoveFromHierarchy();
                    active.RemoveAt(i);
                    continue;
                }
                Vector2 p = RuntimePanelUtils.CameraTransformWorldToPanel(root.panel, f.World + new Vector3(0f, f.Age * 1.4f, 0f), camera);
                f.Label.style.left = p.x;
                f.Label.style.top = p.y;
                f.Label.style.opacity = 1f - Mathf.Max(0f, f.Age - 0.5f) / 0.4f;
            }
        }

        // ---- Menus ----

        public void ShowMenu(MenuPage newPage, int selected = 0)
        {
            page = newPage;
            menuLayer.RemoveFromClassList("hidden");
            menuTitle.text = page.Title ?? "";
            menuSubtitle.text = page.Subtitle ?? "";
            menuSubtitle.EnableInClassList("hidden", string.IsNullOrEmpty(page.Subtitle));
            menuBody.text = page.Body ?? "";
            menuBody.EnableInClassList("hidden", string.IsNullOrEmpty(page.Body));
            menuFooter.text = page.Footer ?? "";
            menuFooter.EnableInClassList("hidden", string.IsNullOrEmpty(page.Footer));
            emblem.EnableInClassList("hidden", !page.ShowEmblem);
            menuPanel.EnableInClassList("menu--title", page.ShowEmblem);
            menuItems.Clear();
            itemLabels.Clear();
            for (int i = 0; i < page.Items.Count; i++)
            {
                int index = i;
                var label = new Label();
                label.AddToClassList("menu__item");
                label.EnableInClassList("menu__item--disabled", !page.Items[i].Enabled);
                label.RegisterCallback<ClickEvent>(_ => Click(index));
                label.RegisterCallback<PointerEnterEvent>(_ =>
                {
                    if (page != null && index < page.Items.Count && page.Items[index].Enabled) Select(index);
                });
                menuItems.Add(label);
                itemLabels.Add(label);
            }
            Selected = Mathf.Clamp(selected, 0, Mathf.Max(0, page.Items.Count - 1));
            if (page.Items.Count > 0 && !page.Items[Selected].Enabled) Move(1);
            Refresh();
        }

        public void HideMenu()
        {
            page = null;
            menuLayer.AddToClassList("hidden");
        }

        /// <summary>Moves the highlight up (-1) or down (+1), skipping disabled items.</summary>
        public void Move(int step)
        {
            if (page == null || page.Items.Count == 0) return;
            int next = Selected;
            for (int i = 0; i < page.Items.Count; i++)
            {
                next = (next + step + page.Items.Count) % page.Items.Count;
                if (page.Items[next].Enabled) break;
            }
            Select(next);
        }

        public void Select(int index)
        {
            Selected = index;
            Refresh();
        }

        /// <summary>Refreshes item text (values change as settings are nudged).</summary>
        public void Refresh()
        {
            if (page == null) return;
            for (int i = 0; i < itemLabels.Count; i++)
            {
                MenuItem item = page.Items[i];
                string value = item.Value?.Invoke();
                string text = item.Label + (string.IsNullOrEmpty(value) ? "" : "   " + (item.Adjust != null ? "< " + value + " >" : value));
                itemLabels[i].text = text;
                itemLabels[i].EnableInClassList("menu__item--selected", i == Selected);
            }
        }

        public event Action<int> ItemClicked;

        void Click(int index)
        {
            if (page == null || index >= page.Items.Count || !page.Items[index].Enabled) return;
            Select(index);
            ItemClicked?.Invoke(index);
        }

        // ---- Helpers ----

        VisualElement Layer(string classes)
        {
            var layer = Box(root, "layer " + classes);
            layer.pickingMode = PickingMode.Ignore;
            return layer;
        }

        static VisualElement Box(VisualElement parent, string classes)
        {
            var element = new VisualElement { pickingMode = PickingMode.Ignore };
            foreach (string c in classes.Split(' ')) element.AddToClassList(c);
            parent.Add(element);
            return element;
        }

        static Label Text(VisualElement parent, string classes, string text)
        {
            var label = new Label(text) { pickingMode = PickingMode.Ignore };
            foreach (string c in classes.Split(' ')) label.AddToClassList(c);
            parent.Add(label);
            return label;
        }
    }
}
