// Cria a chave de upload do Google Play e o arquivo android/key.properties.
//
// Uso (dentro da pasta do projeto):
//   dart run tool/criar_chave.dart
//
// IMPORTANTE: guarde o arquivo android/upload-keystore.jks e a senha em um
// lugar seguro (pendrive, gerenciador de senhas). Sem eles você não consegue
// enviar atualizações do app (dá para pedir troca ao Google, mas demora).
import 'dart:io';

const _keystore = 'android/upload-keystore.jks';
const _properties = 'android/key.properties';

void main() {
  if (!Directory('android').existsSync()) {
    stderr.writeln('✗ Pasta android/ não encontrada. Rode o flutter create primeiro.');
    exit(1);
  }
  if (File(_keystore).existsSync()) {
    stdout.writeln('ℹ️  A chave já existe em $_keystore. Nada foi alterado.');
    stdout.writeln('   Se perdeu a senha, veja o PUBLICAR_GOOGLE_PLAY.md (seção "Perdi a chave").');
    exit(0);
  }

  final keytool = _findKeytool();
  if (keytool == null) {
    stderr.writeln('''
✗ Não achei o "keytool" (ele vem junto com o Android Studio).
  Rode "flutter doctor -v", veja a linha "Java binary at: ..." e use o keytool
  da mesma pasta, ou instale o Android Studio e tente de novo.''');
    exit(1);
  }

  stdout.writeln('Vamos criar a chave de upload do Google Play.\n');
  final name = _ask('Seu nome ou nome da empresa: ');
  final city = _ask('Cidade: ');
  final state = _ask('Estado (ex.: SP): ');
  String password;
  while (true) {
    password = _ask('Crie uma senha (mínimo 6 caracteres): ', hidden: true);
    if (password.length < 6) {
      stdout.writeln('A senha precisa ter pelo menos 6 caracteres.');
      continue;
    }
    final again = _ask('Repita a senha: ', hidden: true);
    if (again == password) break;
    stdout.writeln('As senhas não conferem. Tente de novo.');
  }

  final dname = 'CN=${_clean(name)}, L=${_clean(city)}, ST=${_clean(state)}, C=BR';
  final r = Process.runSync(keytool, [
    '-genkeypair',
    '-v',
    '-keystore', _keystore,
    '-storetype', 'JKS',
    '-keyalg', 'RSA',
    '-keysize', '2048',
    '-validity', '10000',
    '-alias', 'upload',
    '-storepass', password,
    '-keypass', password,
    '-dname', dname,
  ]);
  if (r.exitCode != 0) {
    stderr.writeln('✗ O keytool falhou:\n${r.stderr}');
    exit(1);
  }

  File(_properties).writeAsStringSync('''
storePassword=$password
keyPassword=$password
keyAlias=upload
storeFile=../upload-keystore.jks
''');

  stdout.writeln('''

✅ Chave criada!
   • $_keystore
   • $_properties

⚠️  FAÇA AGORA um backup desses dois arquivos e anote a senha.
   Eles não vão para o Git (estão no .gitignore).

Próximo passo: flutter build appbundle
O arquivo para enviar ao Google Play fica em:
   build/app/outputs/bundle/release/app-release.aab''');
}

String _clean(String s) => s.replaceAll(RegExp(r'[,=+<>#;"\\]'), ' ').trim();

String _ask(String label, {bool hidden = false}) {
  stdout.write(label);
  if (hidden && stdin.hasTerminal) stdin.echoMode = false;
  final v = stdin.readLineSync()?.trim() ?? '';
  if (hidden && stdin.hasTerminal) {
    stdin.echoMode = true;
    stdout.writeln();
  }
  return v.isEmpty && !hidden ? 'Forja' : v;
}

String? _findKeytool() {
  final exe = Platform.isWindows ? 'keytool.exe' : 'keytool';
  final candidates = <String>[
    if (Platform.environment['JAVA_HOME'] != null)
      '${Platform.environment['JAVA_HOME']}/bin/$exe',
    if (Platform.isWindows) ...[
      r'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe',
      r'C:\Program Files\Android\Android Studio\jre\bin\keytool.exe',
      '${Platform.environment['LOCALAPPDATA']}\\Programs\\Android Studio\\jbr\\bin\\keytool.exe',
    ],
    if (Platform.isMacOS) ...[
      '/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool',
      '/Applications/Android Studio.app/Contents/jre/Contents/Home/bin/keytool',
    ],
    if (Platform.isLinux) ...[
      '/opt/android-studio/jbr/bin/keytool',
      '${Platform.environment['HOME']}/android-studio/jbr/bin/keytool',
    ],
  ];
  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  // Por último, tenta o keytool do PATH.
  try {
    final r = Process.runSync(exe, ['-help'], runInShell: true);
    if (r.exitCode == 0 || '${r.stdout}${r.stderr}'.contains('keytool')) {
      return exe;
    }
  } catch (_) {}
  return null;
}
