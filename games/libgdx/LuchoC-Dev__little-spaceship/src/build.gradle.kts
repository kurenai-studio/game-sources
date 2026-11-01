// Versions are pinned: every one of them was verified end to end in
// spikes/web-viability, including running in a real browser. Upgrading any of
// them is a deliberate decision, not a side effect of another change.
val gdxVersion by extra("1.14.2")
val gdxTeaVMVersion by extra("1.6.1")
val junitVersion by extra("5.10.2")

subprojects {
    apply(plugin = "java")

    repositories {
        mavenCentral()
    }

    extensions.configure<JavaPluginExtension> {
        // TeaVM does not digest bytecode from the newest Java versions.
        // 17 is the safe point while compiling with the installed JDK 25.
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    dependencies {
        add("testImplementation", platform("org.junit:junit-bom:$junitVersion"))
        add("testImplementation", "org.junit.jupiter:junit-jupiter")
        add("testRuntimeOnly", "org.junit.platform:junit-platform-launcher")
    }

    tasks.withType<Test>().configureEach {
        useJUnitPlatform()
        testLogging {
            events("failed")
        }
    }
}
