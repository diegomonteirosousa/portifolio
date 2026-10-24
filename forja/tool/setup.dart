// Configura o projeto Android gerado pelo `flutter create` e deixa tudo
// pronto para rodar e publicar no Google Play.
//
// Uso (dentro da pasta do projeto):
//   flutter create --org com.diegomonteiro --project-name forja_fit --platforms android .
//   flutter pub get
//   dart run tool/setup.dart
//
// O script é seguro para rodar mais de uma vez.
import 'dart:io';

void main() {
  var ok = true;
  ok &= _manifest();
  ok &= _gradle();
  ok &= _proguard();
  ok &= _notificationIcon();
  _gitignore();
  _ios();
  ok &= _run('flutter', ['pub', 'get'], 'Dependências instaladas');
  ok &= _run('dart', ['run', 'flutter_launcher_icons'], 'Ícone do app gerado');
  ok &= _run('dart', ['run', 'flutter_native_splash:create'],
      'Tela de abertura gerada');

  final appId = _applicationId();
  stdout.writeln(ok
      ? '\n✅ Pronto! Para testar: flutter run'
          '\n   ID do app no Google Play: ${appId ?? '(não encontrado)'}'
          '\n   Para publicar: dart run tool/criar_chave.dart e depois flutter build appbundle'
      : '\n⚠️  Algumas etapas não foram aplicadas. Veja as mensagens acima e o PUBLICAR_GOOGLE_PLAY.md.');
}

bool _run(String cmd, List<String> args, String done) {
  stdout.writeln('… $cmd ${args.join(' ')}');
  final r = Process.runSync(cmd, args, runInShell: true);
  if (r.exitCode != 0) {
    stdout.writeln(r.stdout);
    stderr.writeln(r.stderr);
    stdout.writeln('✗ Falhou: $cmd ${args.join(' ')}');
    return false;
  }
  stdout.writeln('✓ $done');
  return true;
}

File? _appGradle() {
  for (final p in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
    final f = File(p);
    if (f.existsSync()) return f;
  }
  return null;
}

String? _applicationId() {
  final f = _appGradle();
  if (f == null) return null;
  final m = RegExp(r'''applicationId\s*=?\s*["']([^"']+)["']''')
      .firstMatch(f.readAsStringSync());
  return m?.group(1);
}

// ---------------------------------------------------------------------------
// AndroidManifest: permissões, receptores de lembretes e nome do app
// ---------------------------------------------------------------------------
bool _manifest() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) {
    stdout.writeln(
        '✗ AndroidManifest.xml não encontrado. Rode o flutter create primeiro.');
    return false;
  }
  var xml = f.readAsStringSync();

  // Só o necessário. Nada de localização em segundo plano (ACCESS_BACKGROUND_LOCATION):
  // a corrida usa um serviço em primeiro plano com notificação visível.
  const perms = [
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_LOCATION',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.VIBRATE',
    'android.permission.WAKE_LOCK',
  ];
  final missing = perms.where((p) => !xml.contains('"$p"')).toList();
  if (missing.isNotEmpty) {
    final block = missing
        .map((p) => '    <uses-permission android:name="$p" />')
        .join('\n');
    xml = xml.replaceFirst('<application', '$block\n\n    <application');
  }

  if (!xml.contains('ScheduledNotificationReceiver')) {
    const receivers = '''
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
''';
    xml = xml.replaceFirst('</application>', '$receivers    </application>');
  }

  xml = xml.replaceFirst(
      RegExp(r'android:label="[^"]*"'), 'android:label="Forja"');
  f.writeAsStringSync(xml);
  stdout.writeln('✓ Manifest: permissões, lembretes e nome do app');
  return true;
}

// ---------------------------------------------------------------------------
// Gradle: Android 16 (API 36), desugaring e assinatura de release
// ---------------------------------------------------------------------------
bool _gradle() {
  final f = _appGradle();
  if (f == null) {
    stdout.writeln('✗ build.gradle do app não encontrado.');
    return false;
  }
  final kts = f.path.endsWith('.kts');
  var g = f.readAsStringSync();

  if (kts) {
    // Google Play exige targetSdk 36 desde 31/08/2026.
    g = g.replaceFirst('compileSdk = flutter.compileSdkVersion',
        'compileSdk = maxOf(36, flutter.compileSdkVersion)');
    g = g.replaceFirst('targetSdk = flutter.targetSdkVersion',
        'targetSdk = maxOf(36, flutter.targetSdkVersion)');

    if (!g.contains('isCoreLibraryDesugaringEnabled')) {
      g = g.replaceFirst(RegExp(r'compileOptions\s*\{'),
          'compileOptions {\n        isCoreLibraryDesugaringEnabled = true');
      g += '\ndependencies {\n'
          '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n'
          '}\n';
    }

    if (!g.contains('keystoreProperties')) {
      g = 'import java.io.FileInputStream\nimport java.util.Properties\n\n$g';
      g = g.replaceFirst(RegExp(r'\nandroid\s*\{'), '''

// Chave de upload do Google Play (criada por tool/criar_chave.dart).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
''');
      g = g.replaceFirst('signingConfig = signingConfigs.getByName("debug")',
          'signingConfig = if (keystorePropertiesFile.exists()) '
              'signingConfigs.getByName("release") '
              'else signingConfigs.getByName("debug")');
    }
  } else {
    g = g.replaceFirst(RegExp(r'compileSdk(Version)? flutter\.compileSdkVersion'),
        'compileSdk Math.max(36, flutter.compileSdkVersion)');
    g = g.replaceFirst(RegExp(r'targetSdk(Version)? flutter\.targetSdkVersion'),
        'targetSdkVersion Math.max(36, flutter.targetSdkVersion)');
    if (!g.contains('coreLibraryDesugaringEnabled')) {
      g = g.replaceFirst(RegExp(r'compileOptions\s*\{'),
          'compileOptions {\n        coreLibraryDesugaringEnabled true');
      g += "\ndependencies {\n"
          "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n"
          "}\n";
    }
    if (!g.contains('keystoreProperties')) {
      g = g.replaceFirst(RegExp(r'\nandroid\s*\{'), '''

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
''');
      g = g.replaceFirst('signingConfig signingConfigs.debug',
          'signingConfig keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug');
    }
  }

  f.writeAsStringSync(g);
  stdout.writeln('✓ Gradle: Android 16 (API 36), desugaring e assinatura de release');
  return true;
}

/// Sem estas regras, a versão de loja quebra os lembretes agendados
/// (o plugin de notificações usa Gson, que o R8 removeria).
bool _proguard() {
  final dir = Directory('android/app');
  if (!dir.existsSync()) return false;
  File('android/app/proguard-rules.pro').writeAsStringSync('''
## Regras do Forja para a versão de loja (R8)

## flutter_local_notifications usa Gson para salvar os lembretes agendados
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.** { *; }
''');
  stdout.writeln('✓ R8: regras para os lembretes funcionarem na versão de loja');
  return true;
}

/// Android exige um ícone branco e transparente nas notificações.
bool _notificationIcon() {
  final src = File('assets/icon/ic_stat_forja.png');
  final res = Directory('android/app/src/main/res');
  if (!src.existsSync() || !res.existsSync()) return true;
  final dir = Directory('${res.path}/drawable-xxxhdpi')
    ..createSync(recursive: true);
  src.copySync('${dir.path}/ic_stat_forja.png');
  // Evita que a versão de loja remova os ícones por parecerem "não usados".
  Directory('${res.path}/raw').createSync(recursive: true);
  File('${res.path}/raw/keep.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<resources xmlns:tools="http://schemas.android.com/tools"\n'
      '    tools:keep="@drawable/ic_stat_forja,@mipmap/ic_launcher,@mipmap/launcher_icon" />\n');
  stdout.writeln('✓ Ícone de notificação');
  return true;
}

/// A chave de upload e as senhas nunca devem ir para o Git.
void _gitignore() {
  final f = File('android/.gitignore');
  if (!f.existsSync()) return;
  var s = f.readAsStringSync();
  for (final line in ['key.properties', '*.jks', '*.keystore']) {
    if (!s.split('\n').contains(line)) s += '\n$line';
  }
  f.writeAsStringSync('$s\n');
}

/// iOS é opcional (o foco é o Google Play). Se a pasta existir, configura.
void _ios() {
  final f = File('ios/Runner/Info.plist');
  if (!f.existsSync()) return;
  var plist = f.readAsStringSync();
  final entries = <String, String>{
    'NSLocationWhenInUseUsageDescription':
        '<string>Usamos sua localização para medir distância e ritmo das corridas.</string>',
    'NSLocationAlwaysAndWhenInUseUsageDescription':
        '<string>Permite continuar medindo a corrida com a tela bloqueada.</string>',
    'UIBackgroundModes': '<array>\n\t\t<string>location</string>\n\t</array>',
  };
  final buf = StringBuffer();
  entries.forEach((k, v) {
    if (!plist.contains('<key>$k</key>')) buf.write('\t<key>$k</key>\n\t$v\n');
  });
  if (buf.isNotEmpty) plist = plist.replaceFirst('<dict>', '<dict>\n$buf');
  f.writeAsStringSync(plist);
  stdout.writeln('✓ iOS: permissões de localização');
}
