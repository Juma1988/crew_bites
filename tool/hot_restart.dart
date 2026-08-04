import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Hot-restart (full reload) via VM service.
/// Usage: dart run tool/hot_restart.dart ws://127.0.0.1:PORT/TOKEN/ws
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/hot_restart.dart <ws-url>');
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
        'params': params ?? {},
      }),
    );
    return c.future.timeout(const Duration(seconds: 15));
  }

  // Flutter service extension for hot restart
  final result = await call('ext.flutter.hotRestart', {});
  if (result['error'] != null) {
    // Fallback: reassemble
    final vm = await call('getVM');
    final isolates = (vm['result'] as Map)['isolates'] as List<dynamic>;
    final main = isolates.cast<Map<String, dynamic>>().first;
    await call('ext.flutter.reassemble', {'isolateId': main['id']});
    stdout.writeln('Hot restart unavailable; reassembled instead');
  } else {
    stdout.writeln('Hot restart OK');
  }
  await ws.close();
}
