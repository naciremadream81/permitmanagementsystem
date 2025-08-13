import org.jetbrains.kotlin.gradle.ExperimentalKotlinGradlePluginApi
import org.jetbrains.kotlin.gradle.ExperimentalWasmDsl
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.targets.js.webpack.KotlinWebpackConfig

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidLibrary)
    kotlin("plugin.serialization") version "2.2.0"
    id("app.cash.sqldelight") version "2.0.2"
}

kotlin {
    androidTarget {
        @OptIn(ExperimentalKotlinGradlePluginApi::class)
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_11)
        }
    }
    
    iosX64()
    iosArm64()
    iosSimulatorArm64()
    
    jvm()
    
    // Temporarily disable WASM due to dependency compatibility issues
    // @OptIn(ExperimentalWasmDsl::class)
    // wasmJs {
    //     browser {
    //         val rootDirPath = project.rootDir.path
    //         val projectDirPath = project.projectDir.path
    //         commonWebpackConfig {
    //             devServer = (devServer ?: KotlinWebpackConfig.DevServer()).apply {
    //                 static = (static ?: mutableListOf()).apply {
    //                     // Serve sources to debug inside browser
    //                     add(rootDirPath)
    //                     add(projectDirPath)
    //                 }
    //             }
    //         }
    //     }
    // }
    
    sourceSets {
        commonMain.dependencies {
            // HTTP Client
            implementation("io.ktor:ktor-client-core:2.3.12")
            implementation("io.ktor:ktor-client-content-negotiation:2.3.12")
            implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.12")
            implementation("io.ktor:ktor-client-logging:2.3.12")
            implementation("io.ktor:ktor-client-auth:2.3.12")
            
            // Serialization
            implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.8.1")
            implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
            
            // DateTime
            implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.6.1")
            
            // SQLite for offline storage
            implementation("app.cash.sqldelight:runtime:2.0.2")
            implementation("app.cash.sqldelight:coroutines-extensions:2.0.2")
        }
        
        androidMain.dependencies {
            implementation("io.ktor:ktor-client-android:2.3.12")
            implementation("app.cash.sqldelight:android-driver:2.0.2")
        }
        
        iosMain.dependencies {
            implementation("io.ktor:ktor-client-darwin:2.3.12")
            implementation("app.cash.sqldelight:native-driver:2.0.2")
        }
        
        jvmMain.dependencies {
            implementation("io.ktor:ktor-client-cio:2.3.12")
            implementation("app.cash.sqldelight:sqlite-driver:2.0.2")
            implementation("org.xerial:sqlite-jdbc:3.44.1.0")
        }
        
        // Temporarily disable WASM dependencies
        // wasmJsMain.dependencies {
        //     implementation("io.ktor:ktor-client-js:2.3.12")
        //     // Note: SQLite not available for WASM, will use in-memory storage
        // }
        
        commonTest.dependencies {
            implementation(libs.kotlin.test)
        }
    }
}

android {
    namespace = "com.regnowsnaes.permitmanagementsystem.shared"
    compileSdk = libs.versions.android.compileSdk.get().toInt()
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    defaultConfig {
        minSdk = libs.versions.android.minSdk.get().toInt()
    }
}

sqldelight {
    databases {
        create("PermitDatabase") {
            packageName.set("com.regnowsnaes.permitmanagementsystem.database")
        }
    }
}
