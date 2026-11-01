package dev.meowpow.boxbot.gdx;

import com.badlogic.gdx.utils.ObjectMap;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class ObjectMapViewTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null backing map")
        void should_RejectBackingMap_when_BackingMapIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    new ObjectMapView<String, String>(null)
            );
        }
    }

    @Nested
    @DisplayName("size")
    class SizeMethodTests {

        @Test
        @DisplayName("Returns the backing map size")
        void should_ReturnBackingMapSize_when_MapIsPopulated() {
            var backing = new ObjectMap<String, String>();

            backing.put("first", "one");
            backing.put("second", "two");

            var view = new ObjectMapView<>(backing);

            assertThat(view.size()).isEqualTo(2);
        }
    }

    @Nested
    @DisplayName("isEmpty")
    class IsEmptyMethodTests {

        @Test
        @DisplayName("Returns true for an empty backing map")
        void should_ReturnTrue_when_BackingMapIsEmpty() {
            var view = new ObjectMapView<String, String>(new ObjectMap<>());

            assertThat(view.isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Returns false for a populated backing map")
        void should_ReturnFalse_when_BackingMapIsPopulated() {
            var backing = new ObjectMap<String, String>();

            backing.put("key", "value");

            var view = new ObjectMapView<>(backing);

            assertThat(view.isEmpty()).isFalse();
        }
    }

    @Nested
    @DisplayName("containsKey")
    class ContainsKeyMethodTests {

        @Test
        @DisplayName("Returns true for a present key")
        void should_ReturnTrue_when_KeyIsPresent() {
            var backing = new ObjectMap<String, String>();

            backing.put("key", "value");

            var view = new ObjectMapView<>(backing);

            assertThat(view.containsKey("key")).isTrue();
        }

        @Test
        @DisplayName("Returns false for an absent key")
        void should_ReturnFalse_when_KeyIsAbsent() {
            var view = new ObjectMapView<String, String>(new ObjectMap<>());

            assertThat(view.containsKey("missing")).isFalse();
        }
    }

    @Nested
    @DisplayName("get")
    class GetMethodTests {

        @Test
        @DisplayName("Returns the value for a present key")
        void should_ReturnValue_when_KeyIsPresent() {
            var backing = new ObjectMap<String, String>();

            backing.put("key", "value");

            var view = new ObjectMapView<>(backing);

            assertThat(view.get("key")).isEqualTo("value");
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Returns null for an absent key")
        void should_ReturnNull_when_KeyIsAbsent() {
            var view = new ObjectMapView<String, String>(new ObjectMap<>());

            assertThat(view.get("missing")).isNull();
        }

        @Test
        @DisplayName("Returns the configured default for an absent key")
        void should_ReturnDefaultValue_when_KeyIsAbsent() {
            var view = new ObjectMapView<String, String>(new ObjectMap<>());
            var actual = view.get("missing", "default");

            assertThat(actual).isEqualTo("default");
        }
    }

    @Nested
    @DisplayName("liveView")
    class LiveViewTests {

        @Test
        @DisplayName("Reflects changes to the backing map")
        void should_ReflectChanges_when_BackingMapIsModified() {
            var backing = new ObjectMap<String, String>();

            backing.put("first", "one");

            var view = new ObjectMapView<>(backing);

            backing.remove("first");
            backing.put("second", "two");

            assertThat(view.size()).isOne();
            assertThat(view.containsKey("first")).isFalse();
            assertThat(view.get("second")).isEqualTo("two");
        }
    }
}
