package dev.meowpow.boxbot.architecture;

import dev.meowpow.boxbot.gdx.HotPath;

import com.tngtech.archunit.core.domain.JavaConstructor;
import com.tngtech.archunit.core.domain.JavaField;
import com.tngtech.archunit.core.domain.JavaFieldAccess;
import com.tngtech.archunit.core.domain.JavaFieldAccess.AccessType;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchCondition;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.lang.ConditionEvents;
import com.tngtech.archunit.lang.SimpleConditionEvent;
import com.tngtech.archunit.lang.syntax.elements.GivenClassesConjunction;

import java.util.*;
import java.util.stream.BaseStream;

import static com.tngtech.archunit.core.domain.JavaClass.Predicates.resideInAPackage;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.fields;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

@SuppressWarnings("unused")
@AnalyzeClasses(packages = "dev.meowpow.boxbot")
class HotPathArchitectureTest {

    @ArchTest
    static final ArchRule hotPathClasses_should_NotUseCollections =
            noHotPathClasses()
                    .should()
                    .dependOnClassesThat()
                    .areAssignableTo(Collection.class)
                    .because("hot-path classes must avoid Java collections");

    @ArchTest
    static final ArchRule hotPathClasses_should_NotUseMaps =
            noHotPathClasses()
                    .should()
                    .dependOnClassesThat()
                    .areAssignableTo(Map.class)
                    .because("hot-path classes must avoid Java maps");

    @ArchTest
    static final ArchRule hotPathClasses_should_NotUseIterators =
            noHotPathClasses()
                    .should()
                    .dependOnClassesThat()
                    .areAssignableTo(Iterator.class)
                    .because("hot-path classes must avoid Java iterators");

    @ArchTest
    static final ArchRule hotPathClasses_should_NotUseSpliterators =
            noHotPathClasses()
                    .should()
                    .dependOnClassesThat()
                    .areAssignableTo(Spliterator.class)
                    .because("hot-path classes must avoid Java spliterators");

    @ArchTest
    static final ArchRule hotPathClasses_should_NotUseStreams =
            noHotPathClasses()
                    .should()
                    .dependOnClassesThat()
                    .areAssignableTo(BaseStream.class)
                    .because("hot-path classes must avoid Java streams");

    @ArchTest
    static final ArchRule hotPathFunctionalInterfaceFields_should_OnlyBeAssignedInConstructors =
            fields()
                    .that()
                    .areDeclaredInClassesThat()
                    .areAnnotatedWith(HotPath.class)
                    .and()
                    .haveRawType(resideInAPackage("java.util.function.."))
                    .should(onlyBeAssignedInConstructors())
                    .because("hot-path classes must not allocate functional-interface outside constructor");

    @ArchTest
    static final ArchRule hotPathClasses_should_NotUseOptional =
            noHotPathClasses()
                    .should()
                    .dependOnClassesThat()
                    .areAssignableTo(Optional.class)
                    .orShould()
                    .dependOnClassesThat()
                    .areAssignableTo(OptionalInt.class)
                    .orShould()
                    .dependOnClassesThat()
                    .areAssignableTo(OptionalLong.class)
                    .orShould()
                    .dependOnClassesThat()
                    .areAssignableTo(OptionalDouble.class)
                    .because("hot-path classes must avoid optional wrappers");

    @ArchTest
    static final ArchRule hotPathClasses_should_NotUseFormatter =
            noHotPathClasses()
                    .should()
                    .dependOnClassesThat()
                    .areAssignableTo(Formatter.class)
                    .because("hot-path classes must avoid runtime formatting");

    private static GivenClassesConjunction noHotPathClasses() {
        return noClasses().that().areAnnotatedWith(HotPath.class);
    }

    private static ArchCondition<JavaField> onlyBeAssignedInConstructors() {
        return new ArchCondition<>("only be assigned in constructors") {
            @Override
            public void check(JavaField field, ConditionEvents events) {
                for (JavaFieldAccess access : field.getAccessesToSelf()) {
                    if (access.getAccessType() != AccessType.SET) {
                        continue;
                    }
                    if (access.getOrigin() instanceof JavaConstructor) {
                        continue;
                    }
                    String message = String.format(
                            "Field <%s> is assigned outside a constructor in %s",
                            field.getFullName(),
                            access.getOrigin().getFullName()
                    );
                    events.add(SimpleConditionEvent.violated(access, message));
                }
            }
        };
    }
}
