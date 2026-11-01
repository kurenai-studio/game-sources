package dev.meowpow.boxbot.gdx;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectMap;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class GdxCollectionsTest {

    @Nested
    @DisplayName("emptyView")
    class EmptyViewMethodTests {

        @Test
        @DisplayName("Returns an empty view")
        void should_ReturnEmptyView_when_Called() {
            ArrayView<String> view = GdxCollections.emptyView();

            assertThat(view.isEmpty()).isTrue();
            assertThat(view.size()).isZero();
        }

        @Test
        @DisplayName("Returns the shared view")
        void should_ReturnSameView_when_CalledRepeatedly() {
            var first = GdxCollections.emptyView();
            var second = GdxCollections.emptyView();

            assertThat(first).isSameAs(second);
        }
    }

    @Nested
    @DisplayName("emptyMapView")
    class EmptyMapViewMethodTests {

        @Test
        @DisplayName("Returns an empty view")
        void should_ReturnEmptyView_when_Called() {
            ObjectMapView<String, String> view = GdxCollections.emptyMapView();

            assertThat(view.isEmpty()).isTrue();
            assertThat(view.size()).isZero();
        }

        @Test
        @DisplayName("Returns the shared view")
        void should_ReturnSameView_when_CalledRepeatedly() {
            var first = GdxCollections.emptyMapView();
            var second = GdxCollections.emptyMapView();

            assertThat(first).isSameAs(second);
        }
    }

    @Nested
    @DisplayName("viewOf")
    class ViewOfMethodTests {

        @Test
        @SuppressWarnings({"DataFlowIssue", "ResultOfMethodCallIgnored"})
        @DisplayName("Rejects a null backing array")
        void should_RejectBackingArray_when_BackingArrayIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    GdxCollections.viewOf((Array<?>) null)
            );
        }

        @Test
        @DisplayName("Returns a live view over the backing array")
        void should_ReturnLiveView_when_BackingArrayIsModified() {
            var backing = Array.with("first");
            var view = GdxCollections.viewOf(backing);

            backing.add("second");

            assertThat(view.size()).isEqualTo(2);
            assertThat(view.last()).isEqualTo("second");
        }

        @Test
        @DisplayName("Returns a new view")
        void should_ReturnNewView_when_CalledRepeatedly() {
            var backing = Array.with("element");

            var first = GdxCollections.viewOf(backing);
            var second = GdxCollections.viewOf(backing);

            assertThat(first).isNotSameAs(second);
        }

        @Test
        @SuppressWarnings({"DataFlowIssue", "ResultOfMethodCallIgnored"})
        @DisplayName("Rejects a null backing map")
        void should_RejectBackingMap_when_BackingMapIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    GdxCollections.viewOf((ObjectMap<?, ?>) null)
            );
        }

        @Test
        @DisplayName("Returns a live view over the backing map")
        void should_ReturnLiveView_when_BackingMapIsModified() {
            var backing = new ObjectMap<String, String>();

            backing.put("first", "one");

            var view = GdxCollections.viewOf(backing);

            backing.put("second", "two");

            assertThat(view.size()).isEqualTo(2);
            assertThat(view.get("second")).isEqualTo("two");
        }

        @Test
        @DisplayName("Returns a new view over the backing map")
        void should_ReturnNewView_when_CalledRepeatedlyWithMap() {
            var backing = new ObjectMap<String, String>();

            var first = GdxCollections.viewOf(backing);
            var second = GdxCollections.viewOf(backing);

            assertThat(first).isNotSameAs(second);
        }
    }
}
