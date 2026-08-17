import 'dart:io';
import 'dart:convert';

void main() async {
  print('Applying branding from config/game_config.json...');

  final configFile = File('config/game_config.json');
  if (!configFile.existsSync()) {
    print('Error: config/game_config.json not found');
    exit(1);
  }

  final config = jsonDecode(configFile.readAsStringSync());
  final appName = config['app']['name'] as String;
  final packageId = config['app']['packageId'] as String;

  print('App Name: $appName');
  print('Package ID: $packageId');

  // 1. Update AndroidManifest.xml label
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (manifestFile.existsSync()) {
    var content = manifestFile.readAsStringSync();
    content = content.replaceFirst(
      RegExp(r'android:label="[^"]*"'),
      'android:label="$appName"',
    );
    manifestFile.writeAsStringSync(content);
    print('Updated AndroidManifest.xml label');
  }

  // 2. Update build.gradle applicationId
  final gradleFile = File('android/app/build.gradle');
  if (gradleFile.existsSync()) {
    var content = gradleFile.readAsStringSync();
    content = content.replaceFirst(
      RegExp(r'applicationId "[^"]*"'),
      'applicationId "$packageId"',
    );
    // Also update namespace to match packageId for consistency
    content = content.replaceFirst(
      RegExp(r'namespace "[^"]*"'),
      'namespace "$packageId"',
    );
    gradleFile.writeAsStringSync(content);
    print('Updated build.gradle applicationId and namespace');
  }

  print('Branding applied successfully.');
}
