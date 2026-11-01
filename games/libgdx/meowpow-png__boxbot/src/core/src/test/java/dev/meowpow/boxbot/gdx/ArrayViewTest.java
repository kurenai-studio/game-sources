package dev.meowpow.boxbot.gdx;

import com.badlogic.gdx.utils.Array;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.NoSuchElementException;

import static org.assertj.core.api.Assertions.*;

class ArrayViewTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null backing array")
        void should_RejectBackingArray_when_BackingArrayIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    new ArrayView<>(null)
            );
        }
    }

    @Nested
    @DisplayName("size")
    class SizeMethodTests {

        @Test
        @DisplayName("Returns the backing array size")
        void should_ReturnBackingArraySize_when_ArrayIsPopulated() {
            var view = new ArrayView<>(Array.with("first", "second"));

            assertThat(view.size()).isEqualTo(2);
        }
    }

    @Nested
    @DisplayName("isEmpty")
    class IsEmptyMethodTests {

        @Test
        @DisplayName("Returns true for an empty backing array")
        void should_ReturnTrue_when_BackingArrayIsEmpty() {
            var view = new ArrayView<>(new Array<String>());

            assertThat(view.isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Returns false for a populated backing array")
        void should_ReturnFalse_when_BackingArrayIsPopulated() {
            var view = new ArrayView<>(Array.with("element"));

            assertThat(view.isEmpty()).isFalse();
        }
    }

    @Nested
    @DisplayName("get")
    class GetMethodTests {

        @Test
        @DisplayName("Returns the element at the requested index")
        void should_ReturnElement_when_IndexIsValid() {
            var view = new ArrayView<>(Array.with("first", "second"));

            assertThat(view.get(1)).isEqualTo("second");
        }

        @Test
        @DisplayName("Rejects a negative index")
        void should_RejectIndex_when_IndexIsNegative() {
            var view = new ArrayView<>(Array.with("element"));

            assertThatIndexOutOfBoundsException().isThrownBy(
                    () -> view.get(-1)
            );
        }

        @Test
        @DisplayName("Rejects an index equal to the view size")
        void should_RejectIndex_when_IndexEqualsSize() {
            var backing = new Array<String>(4);

            backing.add("element");

            var view = new ArrayView<>(backing);

            assertThatIndexOutOfBoundsException().isThrownBy(() ->
                    view.get(view.size())
            );
        }
    }

    @Nested
    @DisplayName("first")
    class FirstMethodTests {

        @Test
        @DisplayName("Returns the first element")
        void should_ReturnFirstElement_when_ViewIsPopulated() {
            var view = new ArrayView<>(Array.with("first", "second"));

            assertThat(view.first()).isEqualTo("first");
        }

        @Test
        @DisplayName("Rejects an empty view")
        void should_RejectView_when_ViewIsEmpty() {
            assertThatThrownBy(new ArrayView<>(new Array<String>())::first)
                    .isInstanceOf(NoSuchElementException.class);
        }
    }

    @Nested
    @DisplayName("last")
    class LastMethodTests {

        @Test
        @DisplayName("Returns the last element")
        void should_ReturnLastElement_when_ViewIsPopulated() {
            var view = new ArrayView<>(Array.with("first", "second"));

            assertThat(view.last()).isEqualTo("second");
        }

        @Test
        @DisplayName("Rejects an empty view")
        void should_RejectView_when_ViewIsEmpty() {
            assertThatThrownBy(new ArrayView<>(new Array<String>())::last)
                    .isInstanceOf(NoSuchElementException.class);
        }
    }

    @Nested
    @DisplayName("liveView")
    class LiveViewTests {

        @Test
        @DisplayName("Reflects changes to the backing array")
        void should_ReflectChanges_when_BackingArrayIsModified() {
            var backing = Array.with("first");
            var view = new ArrayView<>(backing);

            backing.add("second");
            backing.removeIndex(0);

            assertThat(view.size()).isOne();
            assertThat(view.get(0)).isEqualTo("second");
            assertThat(view.first()).isEqualTo("second");
            assertThat(view.last()).isEqualTo("second");
        }
    }
}
