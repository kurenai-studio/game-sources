@file:Suppress("UnstableApiUsage")

plugins {
    `java-library`
    jacoco
}

dependencies {
    implementation(libs.slf4j.api)

    compileOnly(libs.jspecify)

    api(libs.gdx)
    implementation(libs.gdx.freetype)

    testImplementation(libs.junit.jupiter)
    testImplementation(libs.assertj.core)
    testRuntimeOnly(libs.junit.platform.launcher)
}

tasks.test {
    useJUnitPlatform()
}

tasks.jacocoTestReport {
    reports {
        xml.required = true
        html.required = true
    }
}

testing {
    suites {
        register<JvmTestSuite>("archTest") {
            useJUnitJupiter(libs.versions.junit.get())

            dependencies {
                implementation(project())
                implementation(libs.archunit.junit5)
            }
        }
        register<JvmTestSuite>("integrationTest") {
            useJUnitJupiter(libs.versions.junit.get())

            dependencies {
                implementation(project())
                implementation(libs.gdx.backend.headless)
                implementation("${libs.gdx.platform.get()}:natives-desktop")
                implementation("${libs.gdx.freetype.platform.get()}:natives-desktop")
                implementation(libs.assertj.core)
                implementation(libs.awaitility)
            }
        }
    }
}

sourceSets.named("integrationTest") {
    resources.srcDir(rootProject.file("assets"))
    resources.exclude("sprites/**", "**/*.xcf", "*.tiled-project", "*.tiled-session", "fonts/OFL.txt")
}

tasks.named("processIntegrationTestResources") {
    dependsOn(rootProject.tasks.named("packTextures"))
}

tasks.named<Test>("integrationTest") {
    maxParallelForks = 1
}

tasks.jacocoTestReport {
    dependsOn(tasks.test, tasks.named<Test>("integrationTest"))
    executionData(tasks.test.get(), tasks.named<Test>("integrationTest").get())
}

tasks.check {
    dependsOn(testing.suites.named("archTest"))
    dependsOn(testing.suites.named("integrationTest"))
}
