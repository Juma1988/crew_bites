import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Hot-reload a running Flutter app via its VM service WebSocket URL.
/// Usage: dart run tool/hot_reload.dart ws://127.0.0.1:PORT/TOKEN/ws
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/hot_reload.dart <ws-url>');
    exit(64);
  }

  final ws = await WebSocket.connect(args.first);
  final pending = <int, Completer<Map<String, dynamic>>>{};
  var nextId = 0;

  ws.listen((msg) {
    final map = jsonDecode(msg as String) as Map<String, dynamic>;
    final id = map['id'];
    if (id is int && pending.containsKey(id)) {
      pending.remove(id)!.complete(map);
    }
  });

  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic>? params,
  ]) {
    final id = ++nextId;
    final c = Completer<Map<String, dynamic>>();
    pending[id] = c;
    ws.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': ?params,
      }),
    );
    return c.future.timeout(const Duration(seconds: 10));
  }

  final vm = await call('getVM');
  final isolates = (vm['result'] as Map)['isolates'] as List<dynamic>;
  final main = isolates.cast<Map<String, dynamic>>().firstWhere(
        (i) => (i['name'] as String).contains('main'),
        orElse: () => isolates.first as Map<String, dynamic>,
      );
  final isolateId = main['id'] as String;

  // reassemble forces UI rebuild with latest code (hot reload equivalent here)
  final result = await call('ext.flutter.reassemble', {'isolateId': isolateId});
  if (result['error'] != null) {
    stderr.writeln('Hot reload failed: ${result['error']}');
    await ws.close();
    exit(1);
  }

  stdout.writeln('Hot reload OK (reassemble)');
  await ws.close();
}
