plugins { id("com.android.application") }
android { namespace = "ir.sejadalmas.salesagent"; compileSdk = 35
 defaultConfig { applicationId = "ir.sejadalmas.salesagent"; minSdk = 24; targetSdk = 35; versionCode = 4; versionName = "0.1.4" }
 signingConfigs { create("release") { val ks=System.getenv("ANDROID_KEYSTORE_PATH"); if(!ks.isNullOrBlank()){ storeFile=file(ks); storePassword=System.getenv("ANDROID_KEYSTORE_PASSWORD"); keyAlias=System.getenv("ANDROID_KEY_ALIAS"); keyPassword=System.getenv("ANDROID_KEY_PASSWORD") } } }
 buildTypes { getByName("release") { isMinifyEnabled=false; if(!System.getenv("ANDROID_KEYSTORE_PATH").isNullOrBlank()) signingConfig=signingConfigs.getByName("release") } }
}
