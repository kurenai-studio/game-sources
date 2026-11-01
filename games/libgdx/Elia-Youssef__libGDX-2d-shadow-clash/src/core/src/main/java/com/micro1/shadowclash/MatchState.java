package com.micro1.shadowclash;

/**
 * The high-level match flow (rubric: Ready, Fight, Combat, Slow-Motion, Victory, Defeat).
 * SLOWMO_KO is the finishing sequence (the knockout hit + the defeated fighter's animation play
 * in slow motion) before the match settles into VICTORY or DEFEAT. Special-move slow motion is a
 * transient effect layered on FIGHT/COMBAT and tracked separately by {@link ClashWorld#isSlowMotion()}.
 */
public enum MatchState {
    READY,      // "GET READY" for 3s; both fighters idle and locked
    FIGHT,      // "FIGHT" banner shows; input + AI enabled, gameplay live
    COMBAT,     // primary gameplay loop after the banner clears
    SLOWMO_KO,  // finishing hit + defeat animation, in slow motion
    VICTORY,    // player won: "YOU WIN"
    DEFEAT      // player lost: "YOU LOSE"
}
