from src.level_details import LevelDetails


# Levels in play order: the campaign first, then the test maps.
# The position of a level in this tuple is its level_index in GameManager.
LEVELS: tuple[LevelDetails, ...] = (
    LevelDetails(
        's01_level_01.tmx',
        'c1',
        "Top of the Tower",
        "The catapult hurled you to the very top of the Count's cursed tower. Collect keys and open doors. Gather diamonds to reveal the secret passage below."),
    LevelDetails(
        's01_level_02.tmx',
        'c2',
        "Chamber of Spirits",
        "Spirits have claimed these chambers — they cannot be slain, so run. Find the sword and cut down Bluemantles and Lurkers. Drink a potion to restore your strength."),
    LevelDetails(
        's01_level_03.tmx',
        'c3',
        "Floor of Stone Secrets",
        "Boulders can be pushed to block the passages. Reach for the bow when enemies are in range. Descend from the tower into the courtyard."),
    LevelDetails(
        's01_level_04.tmx',
        'c4',
        "The Forsaken Courtyard",
        "The Count's manor stands empty and forsaken. Cross the abandoned courtyard and pass the graveyard. Hellfire devours all living things — stay away."),
    LevelDetails(
        's01_level_05.tmx',
        'c5',
        "Cellars of Nightmares",
        "Duskwings and bloodthirsty Webmasters lurk in every shadow. Bloodclaws are lightning-fast and hear your every step. The green spirits haunting this level are terrifyingly fast."),
    LevelDetails(
        's01_level_06.tmx',
        'c6',
        "The Portal Labyrinth",
        "The Count's dark magic raises monsters and tears open portals of teleportation. Traverse the chambers and collect diamonds guarded by spirits and goblins. Step through the portals to reach chambers otherwise inaccessible."),
    LevelDetails(
        's01_level_07.tmx',
        'c7',
        "Dungeons of Eternal Night",
        "Thick darkness engulfs the dungeons — your lantern is your only hope. Webmasters lurk around every corner. Not all walls are what they seem."),
    LevelDetails(
        's01_level_08.tmx',
        'c8',
        "The Antechamber of Hell",
        "You'll find the magic of Explosion — it destroys monsters even through walls. Hidden alcoves are scattered throughout — explore every corner. Hordes of frenzied Duskwings stand guard at every portal."),
    LevelDetails(
        's01_level_09.tmx',
        'c9',
        "The Count's Infernal Keep",
        "Collect all diamonds — the walls will crack. Claim the weapons and face the fire-breathing octopus. Beware its goblin spawn — each fireball hatches a new foe.",
        exit_point_enabled=False,
        is_final_level=True),

    # Test maps, reachable only with their secret codes
    LevelDetails('basic.tmx', 'a1'),
    LevelDetails('basic_arena.tmx', 'a2', exit_point_enabled=False),
    LevelDetails('basic_open_arena.tmx', 'a3'),
)
