package com.micro1.immortalcombat;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PlayerControllerTest {

    private static final float EPSILON = 0.0001f;

    @Test
    void startsIdle() {
        PlayerController controller = new PlayerController();

        assertEquals(PlayerState.IDLE, controller.getCurrentState());
        assertFalse(controller.isOneShotActive());
    }

    @Test
    void attacksPlayOnceAndNotifyTheListener() {
        List<PlayerState> attacks = new ArrayList<PlayerState>();
        PlayerController controller = new PlayerController(attacks::add);

        controller.pressPunch();
        assertEquals(PlayerState.PUNCH, controller.getCurrentState());
        controller.update(3 * PlayerController.PUNCH_FRAME);
        assertEquals(PlayerState.IDLE, controller.getCurrentState());

        controller.pressKick();
        assertEquals(PlayerState.KICK, controller.getCurrentState());
        controller.update(3 * PlayerController.KICK_FRAME);
        assertEquals(PlayerState.IDLE, controller.getCurrentState());

        assertEquals(2, attacks.size());
        assertEquals(PlayerState.PUNCH, attacks.get(0));
        assertEquals(PlayerState.KICK, attacks.get(1));
    }

    @Test
    void jumpUsesThreePhasesAndReturnsToIdle() {
        PlayerController controller = new PlayerController();

        controller.pressJump();
        assertEquals(PlayerState.JUMP, controller.getCurrentState());
        assertEquals(0, controller.jumpFrameIndex(0.05f));
        assertEquals(1, controller.jumpFrameIndex(0.30f));
        assertEquals(2, controller.jumpFrameIndex(0.55f));

        controller.update(0.60f);

        assertEquals(PlayerState.IDLE, controller.getCurrentState());
        assertFalse(controller.isOneShotActive());
    }

    @Test
    void oneShotActionsCannotInterruptEachOther() {
        List<PlayerState> attacks = new ArrayList<PlayerState>();
        PlayerController controller = new PlayerController(attacks::add);

        controller.pressPunch();
        controller.pressKick();
        controller.pressJump();

        assertEquals(PlayerState.PUNCH, controller.getCurrentState());
        assertEquals(1, attacks.size());
    }

    @Test
    void heldActionsRemainActiveUntilReleased() {
        PlayerController controller = new PlayerController();

        controller.setForwardHeld(true);
        controller.update(0.5f);
        assertEquals(PlayerState.FORWARD, controller.getCurrentState());
        controller.setForwardHeld(false);

        controller.setBackwardHeld(true);
        controller.update(0.5f);
        assertEquals(PlayerState.BACKWARD, controller.getCurrentState());
        controller.setBackwardHeld(false);

        controller.setCrouchHeld(true);
        controller.update(0.5f);
        assertEquals(PlayerState.CROUCH, controller.getCurrentState());
        controller.setCrouchHeld(false);

        controller.setBlockHeld(true);
        controller.update(0.5f);
        assertEquals(PlayerState.BLOCK, controller.getCurrentState());
        controller.setBlockHeld(false);
        controller.update(0f);

        assertEquals(PlayerState.IDLE, controller.getCurrentState());
    }

    @Test
    void heldInputPriorityIsDeterministic() {
        PlayerController controller = new PlayerController();
        controller.setBackwardHeld(true);
        controller.setForwardHeld(true);
        controller.setCrouchHeld(true);
        controller.setBlockHeld(true);

        controller.update(0f);
        assertEquals(PlayerState.BLOCK, controller.getCurrentState());
        controller.setBlockHeld(false);

        controller.update(0f);
        assertEquals(PlayerState.CROUCH, controller.getCurrentState());
        controller.setCrouchHeld(false);

        controller.update(0f);
        assertEquals(PlayerState.FORWARD, controller.getCurrentState());
        controller.setForwardHeld(false);

        controller.update(0f);
        assertEquals(PlayerState.BACKWARD, controller.getCurrentState());
    }

    @Test
    void completedOneShotResumesHeldAction() {
        PlayerController controller = new PlayerController();
        controller.setForwardHeld(true);
        controller.pressPunch();

        controller.update(3 * PlayerController.PUNCH_FRAME);

        assertEquals(PlayerState.FORWARD, controller.getCurrentState());
        assertEquals(0f, controller.getStateTime(), EPSILON);
    }

    @Test
    void largeUpdateCreditsOnlyOverflowToTheNextState() {
        PlayerController controller = new PlayerController();
        controller.setForwardHeld(true);
        controller.pressPunch();

        controller.update(3 * PlayerController.PUNCH_FRAME + 0.1f);

        assertEquals(PlayerState.FORWARD, controller.getCurrentState());
        assertEquals(0.1f, controller.getStateTime(), EPSILON);
    }

    @Test
    void frameDurationsMatchTheAnimationContract() {
        assertEquals(0.1f, PlayerController.IDLE_FRAME, EPSILON);
        assertEquals(0.1f, PlayerController.FORWARD_FRAME, EPSILON);
        assertEquals(0.1f, PlayerController.BACKWARD_FRAME, EPSILON);
        assertEquals(0.08f, PlayerController.PUNCH_FRAME, EPSILON);
        assertEquals(0.08f, PlayerController.KICK_FRAME, EPSILON);
        assertEquals(0.08f, PlayerController.BLOCK_FRAME, EPSILON);
        assertEquals(0.08f, PlayerController.CROUCH_FRAME, EPSILON);
        assertEquals(0.1f, PlayerController.JUMP_LAUNCH_FRAME, EPSILON);
        assertEquals(0.4f, PlayerController.JUMP_MIDAIR_FRAME, EPSILON);
        assertEquals(0.1f, PlayerController.JUMP_LAND_FRAME, EPSILON);
        assertTrue(PlayerController.FRAMES_PER_ACTION >= 3);
        assertArrayEquals(
            new PlayerState[] {
                PlayerState.IDLE,
                PlayerState.PUNCH,
                PlayerState.KICK,
                PlayerState.FORWARD,
                PlayerState.BACKWARD,
                PlayerState.JUMP,
                PlayerState.CROUCH,
                PlayerState.BLOCK
            },
            PlayerState.values()
        );
    }

    @Test
    void rejectsNegativeTime() {
        PlayerController controller = new PlayerController();

        assertThrows(IllegalArgumentException.class, () -> controller.update(-0.01f));
    }
}
