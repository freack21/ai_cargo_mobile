// Minimal single-file Flutter app for the user's requirements.
// Features:
// - Home page with big background and two menu buttons: 'Kontrol Manual' and 'Rangkai Perintah'
// - Manual control page with buttons: Maju, Mundur, Putar Kanan, Putar Kiri
// - Command sequence page with ReorderableListView for cards, each card has a time input and delete
// - Add command page to add new command card
// - Header on Manual and Rangkai pages: shows socket.io connection status, 'Cek Koneksi' and 'Hubungkan'
// - Save commands to SharedPreferences as JSON and Run (emit 'run-commands' via socket.io)
// Note: This is a single-file example to get you started. For production split into multiple files.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

void main() {
  runApp(const RobotLearningApp());
}

class RobotLearningApp extends StatefulWidget {
  const RobotLearningApp({super.key});

  @override
  State<RobotLearningApp> createState() => _RobotLearningAppState();
}

class _RobotLearningAppState extends State<RobotLearningApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Pembelajaran',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Models ---
class Command {
  String type; // 'maju', 'mundur', 'putar_kanan', 'putar_kiri'
  int speed;
  double durationSeconds;

  Command(
      {required this.type, required this.speed, required this.durationSeconds});

  Map<String, dynamic> toJson() => {
        'type': type,
        'speed': speed,
        'time': durationSeconds,
      };

  factory Command.fromJson(Map<String, dynamic> j) => Command(
        type: j['type'],
        speed: j['speed'],
        durationSeconds: j['time'],
      );
}

// --- Service: SocketManager ---
class SocketManager {
  socket_io.Socket? socket;
  String? url;

  final ValueNotifier<bool> connected = ValueNotifier(false);

  void init(String serverUrl) {
    url = serverUrl;
  }

  void connect() {
    if (url == null) return;
    socket = socket_io.io(
      url!,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.on('connect', (_) {
      connected.value = true;
      socket!.emit('join', 'basestation');
    });

    socket!.on('disconnect', (_) {
      connected.value = false;
    });

    socket!.connect();
  }

  Future<bool> checkConnection() async {
    // quick check: socket connected or not
    return socket != null && socket!.connected;
  }

  void emitRunCommands(List<Command> commands) {
    if (socket == null || !socket!.connected) return;
    final payload = commands.map((c) => c.toJson()).toList();
    socket!.emit('run-commands', {'commands': payload, 'robot': 'aikargo'});
  }

  void dispose() {
    socket?.dispose();
    connected.dispose();
  }
}

final SocketManager socketManager = SocketManager();

// --- Home Page ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: replace with an asset suited for kids
          Image.asset(
            'assets/bg_robot_kids.jpg',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                Container(color: Colors.blueGrey.shade100),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Robot & Massa (GLB)',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _menuButton(context, 'Kontrol Manual', Icons.gamepad,
                          const ManualControlPage()),
                      const SizedBox(height: 16),
                      _menuButton(context, 'Rangkai Perintah', Icons.list_alt,
                          const CommandSequencePage()),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _menuButton(
      BuildContext ctx, String title, IconData icon, Widget toPage) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          backgroundColor: Colors.orangeAccent.withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(icon, size: 36),
        label: Text(title),
        onPressed: () =>
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => toPage)),
      ),
    );
  }
}

// --- Header widget reused on pages ---
class ConnectionHeader extends StatefulWidget implements PreferredSizeWidget {
  final String serverUrlHint;
  const ConnectionHeader(
      {super.key, this.serverUrlHint = 'ws://145.79.13.55:3210'});

  @override
  State<ConnectionHeader> createState() => _ConnectionHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class _ConnectionHeaderState extends State<ConnectionHeader> {
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(
        text: socketManager.url ?? 'ws://145.79.13.55:3210');
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xAAFFFFFF),
      elevation: 0,
      title: Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: socketManager.connected,
            builder: (ctx, connected, _) {
              return Row(
                children: [
                  Icon(connected ? Icons.cloud_done : Icons.cloud_off,
                      color: connected ? Colors.lightGreen : Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    connected ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Cek Koneksi',
          icon: const Icon(Icons.sync),
          onPressed: () async {
            final ok = await socketManager.checkConnection();
            final snack = ok ? 'Socket terhubung' : 'Socket tidak terhubung';
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(snack)));
          },
        ),
        IconButton(
          tooltip: 'Hubungkan',
          icon: const Icon(Icons.link),
          onPressed: () {
            final url = _urlCtrl.text.trim();
            if (url.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Masukkan URL server')));
              return;
            }
            socketManager.init(url);
            socketManager.connect();
          },
        ),
      ],
    );
  }
}

// --- Manual Control Page ---
class ManualControlPage extends StatefulWidget {
  const ManualControlPage({super.key});

  @override
  State<ManualControlPage> createState() => _ManualControlPageState();
}

class _ManualControlPageState extends State<ManualControlPage> {
  String speed = "75";

  void sendCommand(String type) {
    // For manual control we'll emit a quick message with type and default duration 1 sec
    String cmd = type;
    if (type != "berhenti") {
      cmd = "move|$type:0,$speed";
    }
    socketManager.socket
        ?.emit('kirim-perintah', {'perintah': cmd, 'robot': "aikargo"});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConnectionHeader(),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/bg_robot_kids.jpg'),
            fit: BoxFit.cover,
            onError: (_, __) {},
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 64,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          color: Colors.white,
                        ),
                        child: DropdownButtonFormField<String>(
                          value: speed,
                          items: const [
                            DropdownMenuItem(value: '25', child: Text('25%')),
                            DropdownMenuItem(value: '50', child: Text('50%')),
                            DropdownMenuItem(value: '75', child: Text('75%')),
                            DropdownMenuItem(value: '100', child: Text('100%')),
                          ],
                          onChanged: (v) => setState(() {
                            speed = v ?? '75';
                          }),
                          decoration:
                              const InputDecoration(labelText: 'Kecepatan'),
                        ),
                      ),
                      const SizedBox(
                        height: 64,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ControlButtonGrid(
                              onPressed: (type) => sendCommand(type)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ControlButtonGrid extends StatelessWidget {
  final Function(String) onPressed;
  const ControlButtonGrid({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _bigBtn('Maju', Icons.arrow_upward, 'maju'),
        _bigBtn('Mundur', Icons.arrow_downward, 'mundur'),
        _bigBtn('Putar Kanan', Icons.rotate_right, 'putar_kanan'),
        _bigBtn('Putar Kiri', Icons.rotate_left, 'putar_kiri'),
        _bigBtn('Berhenti', Icons.stop_circle, 'berhenti'),
      ]
          .map((w) => GestureDetector(
              onTap: () => onPressed((w as _BtnData).type), child: w))
          .toList(),
    );
  }

  Widget _bigBtn(String label, IconData icon, String type) {
    return _BtnData(
      type: type,
      child: Container(
        width: 140,
        height: 80,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _BtnData extends StatelessWidget {
  final Widget child;
  final String type;
  const _BtnData({required this.child, required this.type});
  @override
  Widget build(BuildContext context) => child;
}

// --- Command Sequence Page ---
class CommandSequencePage extends StatefulWidget {
  const CommandSequencePage({super.key});

  @override
  State<CommandSequencePage> createState() => _CommandSequencePageState();
}

class _CommandSequencePageState extends State<CommandSequencePage> {
  List<Command> commands = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('saved_commands');
    if (raw != null) {
      try {
        final arr = json.decode(raw) as List;
        setState(() {
          commands = arr.map((e) => Command.fromJson(e)).toList();
        });
      } catch (e) {
        // ignore malformed
      }
    }
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    final raw = json.encode(commands.map((c) => c.toJson()).toList());
    await sp.setString('saved_commands', raw);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tersimpan')));
  }

  void _run() {
    socketManager.emitRunCommands(commands);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perintah dikirim ke server')));
  }

  void _addCommand(Command c) {
    setState(() => commands.add(c));
  }

  void _deleteAt(int idx) {
    setState(() => commands.removeAt(idx));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConnectionHeader(),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/bg_robot_kids.jpg'),
            fit: BoxFit.cover,
            onError: (_, __) {},
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Expanded(
                          child: commands.isEmpty
                              ? const Center(
                                  child: Text(
                                      'Belum ada perintah. Tekan + untuk menambah.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                      )))
                              : ReorderableListView.builder(
                                  itemCount: commands.length,
                                  onReorder: (oldIndex, newIndex) {
                                    setState(() {
                                      if (newIndex > oldIndex) newIndex -= 1;
                                      final item = commands.removeAt(oldIndex);
                                      commands.insert(newIndex, item);
                                    });
                                  },
                                  itemBuilder: (ctx, idx) {
                                    final c = commands[idx];
                                    return ListTile(
                                      key: ValueKey(
                                          '$idx-${c.type}-${c.durationSeconds}-${c.speed}'),
                                      leading: Icon(_iconForType(c.type)),
                                      title: Text(_labelForType(c.type)),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Durasi: ${c.durationSeconds} detik'),
                                          Text('Kecepatan: ${c.speed}%'),
                                        ],
                                      ),
                                      trailing: IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _deleteAt(idx)),
                                    );
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _save,
                                  child: const Text('Simpan'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _run,
                                  child: const Text('Jalankan'),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final res = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddCommandPage()));
          if (res is Command) _addCommand(res);
        },
      ),
    );
  }

  IconData _iconForType(String t) {
    switch (t) {
      case 'maju':
        return Icons.arrow_upward;
      case 'mundur':
        return Icons.arrow_downward;
      case 'putar_kanan':
        return Icons.rotate_right;
      case 'putar_kiri':
        return Icons.rotate_left;
      case 'berhenti':
        return Icons.stop_circle;
      default:
        return Icons.help;
    }
  }

  String _labelForType(String t) {
    switch (t) {
      case 'maju':
        return 'Maju';
      case 'mundur':
        return 'Mundur';
      case 'putar_kanan':
        return 'Putar Kanan';
      case 'putar_kiri':
        return 'Putar Kiri';
      case 'berhenti':
        return 'Berhenti';
      default:
        return t;
    }
  }
}

// --- Add Command Page ---
class AddCommandPage extends StatefulWidget {
  const AddCommandPage({super.key});

  @override
  State<AddCommandPage> createState() => _AddCommandPageState();
}

class _AddCommandPageState extends State<AddCommandPage> {
  String type = 'maju';
  String speed = '75';
  final _durCtrl = TextEditingController(text: '5.0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Perintah')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: 'maju', child: Text('Maju')),
                DropdownMenuItem(value: 'mundur', child: Text('Mundur')),
                DropdownMenuItem(
                    value: 'putar_kanan', child: Text('Putar Kanan')),
                DropdownMenuItem(
                    value: 'putar_kiri', child: Text('Putar Kiri')),
                DropdownMenuItem(value: 'berhenti', child: Text('Berhenti')),
              ],
              onChanged: (v) => setState(() {
                type = v ?? 'maju';
              }),
              decoration: const InputDecoration(labelText: 'Jenis Perintah'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Durasi (detik)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: speed,
              items: const [
                DropdownMenuItem(value: '25', child: Text('25%')),
                DropdownMenuItem(value: '50', child: Text('50%')),
                DropdownMenuItem(value: '75', child: Text('75%')),
                DropdownMenuItem(value: '100', child: Text('100%')),
              ],
              onChanged: (v) => setState(() {
                speed = v ?? '75';
              }),
              decoration: const InputDecoration(labelText: 'Kecepatan'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final d = double.tryParse(_durCtrl.text) ?? 1.0;
                final s = int.tryParse(speed) ?? 75;
                Navigator.pop(
                    context, Command(type: type, durationSeconds: d, speed: s));
              },
              child: const Text('Tambah'),
            )
          ],
        ),
      ),
    );
  }
}

// End of file
