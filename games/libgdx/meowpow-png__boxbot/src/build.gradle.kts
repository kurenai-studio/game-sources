import org.gradle.api.tasks.testing.logging.TestExceptionFormat
import org.gradle.api.tasks.testing.logging.TestLogEvent

repositories {
    mavenCentral()
}

val texturePacker: Configuration = configurations.create("texturePacker")

dependencies {
    texturePacker(libs.gdx.tools)
}

val packTextures = tasks.register<JavaExec>("packTextures") {
    group = "assets"
    description = "Packs loose sprite PNGs from assets/sprites into a texture atlas in assets/atlas"

    val inputDir = file("assets/sprites")
    val outputDir = file("assets/atlas")

    classpath = texturePacker
    mainClass.set("com.badlogic.gdx.tools.texturepacker.TexturePacker")
    args(inputDir.path, outputDir.path, "sprites")

    inputs.dir(inputDir)
    outputs.dir(outputDir)
}

subprojects {
    group = "dev.meowpow.boxbot"

    repositories {
        mavenCentral()
    }

    pluginManager.withPlugin("java") {
        configure<JavaPluginExtension> {
            toolchain {
                languageVersion.set(JavaLanguageVersion.of(21))
            }
        }
    }

    tasks.withType<Test>().configureEach {
        outputs.upToDateWhen { false }
        outputs.cacheIf { false }

        testLogging {
            events(TestLogEvent.PASSED, TestLogEvent.FAILED)
            exceptionFormat = TestExceptionFormat.FULL
        }
    }
}
