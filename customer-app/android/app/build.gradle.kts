plugins { id("com.android.application"); id("org.jetbrains.kotlin.android"); id("org.jetbrains.kotlin.plugin.compose") }
android { namespace="com.lollipop.efis"; compileSdk=35
 defaultConfig { applicationId="com.lollipop.efis"; minSdk=26; targetSdk=35; versionCode=1; versionName="0.2.0" }
 buildFeatures { compose=true }
 compileOptions { sourceCompatibility=JavaVersion.VERSION_17; targetCompatibility=JavaVersion.VERSION_17 }
}
dependencies {
 implementation("androidx.activity:activity-compose:1.10.1")
 implementation(platform("androidx.compose:compose-bom:2025.04.01"))
 implementation("androidx.compose.material3:material3")
 implementation("androidx.compose.material:material-icons-extended")
 implementation("com.journeyapps:zxing-android-embedded:4.3.0")
}
