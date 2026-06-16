plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fiscalize.fiscalize_any_droid"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.fiscalize.fiscalize_any_droid"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }
}

dependencies {
    // HTTP client for PrintService → Fiscalize API calls
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // Encrypted shared preferences for secure credential storage
    implementation("androidx.security:security-crypto:1.1.0-alpha06")

    // Coroutines for async PrintService processing
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // PDF text extraction AND local stamping (mirrors FiscalyzeAny's PdfPig + PdfSharpCore)
    implementation("com.tom_roush:pdfbox-android:2.0.27.0")

    // QR code generation for local PDF stamp (mirrors FiscalyzeAny's QRCoder)
    implementation("com.google.zxing:core:3.5.3")

    // Notifications
    implementation("androidx.core:core-ktx:1.16.0")
}

flutter {
    source = "../.."
}
