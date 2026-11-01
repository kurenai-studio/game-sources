package com.elmagica.game;

public class FeedbackChecks {
    public static void run() {
        require(GameAudio.trackFor(false, false, false) == GameAudio.Track.CALM, "Menu music");
        require(GameAudio.trackFor(true, true, true) == GameAudio.Track.CALM, "Merchant music takes priority");
        require(GameAudio.trackFor(true, false, false) == GameAudio.Track.COMBAT, "Combat floor music");
        require(GameAudio.trackFor(true, false, true) == GameAudio.Track.BOSS, "Boss music");
        CombatText text = new CombatText();
        try {
            CombatSession session = new CombatSession();
            session.hit(new Enemy(ElementType.WATER, 5, 5), ElementType.FIRE);
            session.hit(new Enemy(ElementType.FIRE, 5, 5), ElementType.FIRE);
            session.hit(new Enemy(ElementType.AIR, 5, 5), ElementType.FIRE);
            require(text.labels.get(0).kind == CombatText.Kind.WEAK && text.labels.get(0).text.equals("5"), "Weak enemy hit");
            require(text.labels.get(1).kind == CombatText.Kind.NORMAL && text.labels.get(1).text.equals("10"), "Normal enemy hit");
            require(text.labels.get(2).kind == CombatText.Kind.STRONG && text.labels.get(2).text.equals("20"), "Strong enemy hit");
            Player player = new Player(ElementType.FIRE); player.takeDamage(2, 1);
            require(text.labels.peek().kind == CombatText.Kind.WEAK, "Incoming color uses matchup, not scaled damage");
            player.takeDamage(2, 3); player.heal(100);
            require(text.labels.peek().kind == CombatText.Kind.HEAL && text.labels.peek().text.equals("+4"), "Show actual clamped healing");
            int count = text.labels.size; player.heal(100);
            require(text.labels.size == count, "No false heal at full HP");
            player.dodgeChance = 1; player.takeDamage(10, 3);
            require(player.getHp() == 20 && text.labels.peek().kind == CombatText.Kind.DODGE, "Dodge instead of damage number");
            text.update(1.2f); require(text.labels.isEmpty(), "Floating labels expire");
        } finally { text.dispose(); }
        System.out.println("Feedback checks passed: music scenes, matchup colors, actual healing, dodge and cleanup");
    }
    private static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
}
