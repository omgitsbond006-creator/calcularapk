import os, re, shutil, glob

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

target_namespace = "com.calcular.app"
target_path_parts = target_namespace.split(".")

main_activity_files = glob.glob("android/app/src/main/kotlin/**/MainActivity.kt", recursive=True) + \
                       glob.glob("android/app/src/main/java/**/MainActivity.java", recursive=True)

for old_path in main_activity_files:
    ext = old_path.rsplit(".", 1)[1]
    src_root = "android/app/src/main/kotlin" if "kotlin" in old_path else "android/app/src/main/java"
    new_dir = os.path.join(src_root, *target_path_parts)
    new_path = os.path.join(new_dir, f"MainActivity.{ext}")

    content = open(old_path).read()
    content = re.sub(r'^package\s+[\w.]+', f'package {target_namespace}', content, count=1, flags=re.MULTILINE)

    if os.path.abspath(old_path) != os.path.abspath(new_path):
        os.makedirs(new_dir, exist_ok=True)
        with open(new_path, "w") as f:
            f.write(content)
        os.remove(old_path)
        d = os.path.dirname(old_path)
        while d and d != src_root:
            try:
                os.rmdir(d)
            except OSError:
                break
            d = os.path.dirname(d)
        print(f"moved MainActivity: {old_path} -> {new_path}")
    else:
        with open(new_path, "w") as f:
            f.write(content)
        print(f"MainActivity already at correct path: {new_path}")
