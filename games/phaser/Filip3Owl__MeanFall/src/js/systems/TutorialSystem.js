import { TUTORIAL_TIPS } from '../data/lore.js';
import EventBus from '../utils/EventBus.js';

export const TutorialSystem = {

    init(player) {
        if (!player.seenTutorials) player.seenTutorials = {};
    },

    /** Triggers a tutorial tip if not yet seen. Returns true if shown.
     *  `onDone` roda quando o jogador fecha o diálogo da dica. */
    trigger(player, scene, triggerKey, onDone = null) {
        this.init(player);
        const tip = TUTORIAL_TIPS.find(t => t.trigger === triggerKey);
        if (!tip) return false;
        if (player.seenTutorials[tip.id]) return false;
        player.seenTutorials[tip.id] = true;

        // Launch a Dialog overlay to show it
        scene.scene.launch('Dialog', {
            speaker: 'TUTORIAL',
            lines: [tip.text],
            role: 'quest',
            onClose: () => {
                if (scene.resumeFromOverlay) scene.resumeFromOverlay();
                if (onDone) onDone();
            },
        });
        if (scene.pauseForOverlay) scene.pauseForOverlay();
        EventBus.emit('chat', { msg: `Dica: ${tip.text}`, type: 'hint' });
        return true;
    },

    has(player, tipId) {
        this.init(player);
        return !!player.seenTutorials[tipId];
    },
};
