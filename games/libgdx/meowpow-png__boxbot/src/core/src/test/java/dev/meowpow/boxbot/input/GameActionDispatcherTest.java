package dev.meowpow.boxbot.input;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

class GameActionDispatcherTest {

    @Nested
    @DisplayName("dispatch")
    class DispatchMethodTests {

        @Test
        @DisplayName("Delivers the dispatched action to a registered listener")
        void should_DeliverAction_when_ListenerIsRegistered() {
            var dispatcher = new GameActionDispatcher();
            var received = new AtomicReference<GameAction>();

            dispatcher.addListener(received::set);
            dispatcher.dispatch(GameAction.TOGGLE_FULLSCREEN);

            assertThat(received).hasValue(GameAction.TOGGLE_FULLSCREEN);
        }

        @Test
        @DisplayName("Notifies every registered listener once")
        void should_NotifyEveryListenerOnce_when_ActionIsDispatched() {
            var dispatcher = new GameActionDispatcher();
            var firstCalls = new AtomicInteger();
            var secondCalls = new AtomicInteger();

            dispatcher.addListener(action -> firstCalls.incrementAndGet());
            dispatcher.addListener(action -> secondCalls.incrementAndGet());

            dispatcher.dispatch(GameAction.TOGGLE_FULLSCREEN);

            assertThat(firstCalls).hasValue(1);
            assertThat(secondCalls).hasValue(1);
        }

        @Test
        @DisplayName("Notifies listeners for every successive action")
        void should_NotifyListenersForEveryAction_when_ActionsAreDispatchedSuccessively() {
            var dispatcher = new GameActionDispatcher();
            var received = new ArrayList<GameAction>();

            dispatcher.addListener(received::add);

            dispatcher.dispatch(GameAction.TOGGLE_FULLSCREEN);
            dispatcher.dispatch(GameAction.TOGGLE_FULLSCREEN);

            assertThat(received).containsExactly(
                    GameAction.TOGGLE_FULLSCREEN,
                    GameAction.TOGGLE_FULLSCREEN
            );
        }

        @Test
        @DisplayName("Completes normally when no listeners are registered")
        void should_CompleteNormally_when_NoListenersAreRegistered() {
            var dispatcher = new GameActionDispatcher();
            var action = GameAction.TOGGLE_FULLSCREEN;

            assertThatCode(() -> dispatcher.dispatch(action)).doesNotThrowAnyException();
        }
    }
}
