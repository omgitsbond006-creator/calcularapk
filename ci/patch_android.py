import os, re, shutil

gradle_path = "android/app/build.gradle"
is_kts = False
if os.path.exists("android/app/build.gradle.kts"):
    gradle_path = "android/app/build.gradle.kts"
    is_kts = True

content = open(gradle_path).read()
content = re.sub(r'namespace\s*=?\s*"[^"]+"', 'namespace = "com.calcular.app"', content, count=1)
content = re.sub(r'applicationId\s*=?\s*"[^"]+"', 'applicationId = "com.calcular.app"', content, count=1)

if is_kts:
    imports = 'import java.util.Properties\nimport java.io.FileInputStream\n\n'
    signing_block = '''

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = rootProject.file("../upload-keystore.jks")
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
'''
    content = imports + content + signing_block
else:
    signing_block = '''

def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile rootProject.file('../upload-keystore.jks')
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
'''
    content = content + signing_block

open(gradle_path, "w").write(content)
print("patched", gradle_path)

manifest_path = "android/app/src/main/AndroidManifest.xml"
m = open(manifest_path).read()
m = re.sub(r'android:label="[^"]*"', 'android:label="Calcular"', m, count=1)
open(manifest_path, "w").write(m)
print("patched", manifest_path)

for density in ["mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"]:
    src = f"ci/launcher_icons/mipmap-{density}/ic_launcher.png"
    dst = f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
    if os.path.exists(src):
        shutil.copyfile(src, dst)
        print("copied icon", dst)

proguard_path = "android/app/proguard-rules.pro"
if not os.path.exists(proguard_path):
    with open(proguard_path, "w") as f:
        f.write(
            "# Calcular uses only the Flutter framework with no platform\n"
            "# channels or reflection-dependent packages, so no custom\n"
            "# keep rules are required.\n"
        )
    print("created", proguard_path)
