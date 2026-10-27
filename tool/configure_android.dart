import 'dart:io';

void main() {
  final gradleFile = File('android/app/build.gradle.kts');
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');

  if (!gradleFile.existsSync()) {
    stderr.writeln('android/app/build.gradle.kts tidak ditemukan.');
    exitCode = 1;
    return;
  }
  if (!manifestFile.existsSync()) {
    stderr.writeln('AndroidManifest.xml tidak ditemukan.');
    exitCode = 1;
    return;
  }

  var gradle = gradleFile.readAsStringSync();

  gradle = gradle.replaceAll(
    RegExp(r'compileSdk\s*=\s*flutter\.compileSdkVersion'),
    'compileSdk = 36',
  );
  gradle = gradle.replaceAll(
    RegExp(r'minSdk\s*=\s*flutter\.minSdkVersion'),
    'minSdk = 24',
  );
  gradle = gradle.replaceAll(
    RegExp(r'targetSdk\s*=\s*flutter\.targetSdkVersion'),
    'targetSdk = 36',
  );
  gradle = gradle.replaceAll(
    'JavaVersion.VERSION_11',
    'JavaVersion.VERSION_17',
  );

  if (!gradle.contains('isCoreLibraryDesugaringEnabled = true')) {
    final marker = 'compileOptions {';
    final index = gradle.indexOf(marker);
    if (index == -1) {
      stderr.writeln('Bagian compileOptions tidak ditemukan.');
      exitCode = 1;
      return;
    }
    final insertionPoint = index + marker.length;
    gradle = gradle.substring(0, insertionPoint) +
        '\n        isCoreLibraryDesugaringEnabled = true' +
        gradle.substring(insertionPoint);
  }

  if (!gradle.contains('coreLibraryDesugaring(')) {
    gradle += '''

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
''';
  }

  gradleFile.writeAsStringSync(gradle);

  var manifest = manifestFile.readAsStringSync();

  const permissions = '''
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.VIBRATE" />
''';

  if (!manifest.contains('android.permission.POST_NOTIFICATIONS')) {
    final endOfManifestTag = manifest.indexOf('>');
    if (endOfManifestTag == -1) {
      stderr.writeln('Tag <manifest> tidak valid.');
      exitCode = 1;
      return;
    }
    manifest = manifest.substring(0, endOfManifestTag + 1) +
        '\n$permissions' +
        manifest.substring(endOfManifestTag + 1);
  }

  const receivers = '''
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
''';

  if (!manifest.contains('ScheduledNotificationReceiver')) {
    final applicationClose = manifest.indexOf('</application>');
    if (applicationClose == -1) {
      stderr.writeln('Tag </application> tidak ditemukan.');
      exitCode = 1;
      return;
    }
    manifest = manifest.substring(0, applicationClose) +
        receivers +
        manifest.substring(applicationClose);
  }

  manifest = manifest.replaceFirst(
    RegExp(r'android:label="[^"]*"'),
    'android:label="PelajarKu"',
  );

  manifestFile.writeAsStringSync(manifest);
  stdout.writeln('Konfigurasi Android PelajarKu selesai.');
}
