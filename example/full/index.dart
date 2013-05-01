import 'package:logging/logging.dart';

void main() {
  new Logger('')
      ..level = Level.FINEST
      ..onRecord.listen((r) => print('[${r.level}] ${r.message}'));
}
