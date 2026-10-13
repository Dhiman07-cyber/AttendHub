import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  stdout.writeln('========================================================');
  stdout.writeln('  AttendHub Flutter Live Watcher & Runner');
  stdout.writeln('  Watching lib/ for changes -> Auto Hot Reload on Save');
  stdout.writeln('========================================================');

  final hasEnv = File('.env').existsSync();
  final List<String> flutterArgs = [
    'run',
    '-d',
    'web-server',
    '--web-hostname=127.0.0.1',
    '--web-port=5000',
    if (hasEnv) '--dart-define-from-file=.env',
    ...args,
  ];

  final flutterExecutable = Platform.isWindows ? 'flutter.bat' : 'flutter';

  // Ensure port 5000 is free before launching flutter web runner
  if (Platform.isWindows) {
    try {
      final checkSocket = await ServerSocket.bind('127.0.0.1', 5000);
      await checkSocket.close();
    } catch (_) {
      stdout.writeln('[WatchRun] Port 5000 busy; freeing port from orphan process...');
      try {
        Process.runSync('powershell', [
          '-NoProfile',
          '-Command',
          r'Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }',
        ]);
        await Future.delayed(const Duration(milliseconds: 600));
      } catch (_) {}
    }
  }

  final process = await Process.start(
    flutterExecutable,
    flutterArgs,
    workingDirectory: Directory.current.path,
    mode: ProcessStartMode.normal,
    runInShell: true,
  );

  // Pipe process stdout and stderr
  process.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
  });

  // Forward terminal stdin so manual keystrokes ('r', 'R', 'q', 'h') still work
  try {
    stdin.listen((data) {
      process.stdin.add(data);
    });
  } catch (_) {}

  Timer? debounceTimer;
  DateTime lastReload = DateTime.now();

  void triggerHotReload(String changedPath) {
    final now = DateTime.now();
    if (now.difference(lastReload).inMilliseconds < 500) {
      return;
    }
    lastReload = now;
    final fileName = changedPath.split(Platform.pathSeparator).last;
    stdout.writeln('\n[WatchRun] Change detected in $fileName -> Auto-triggering Hot Reload (r)...');
    process.stdin.writeln('r');
  }

  final libDir = Directory('lib');
  if (libDir.existsSync()) {
    libDir.watch(recursive: true).listen((event) {
      final path = event.path;
      if (path.endsWith('.dart')) {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 350), () {
          triggerHotReload(path);
        });
      }
    });
    stdout.writeln('[WatchRun] Active file watcher started on lib/**/*.dart');
  }

  final exitCode = await process.exitCode;
  exit(exitCode);
}
