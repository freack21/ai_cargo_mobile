import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/socket_service.dart';
import '../models/command_model.dart';

class CommandSequencePage extends StatefulWidget {
  const CommandSequencePage({super.key});

  @override
  State<CommandSequencePage> createState() => _CommandSequencePageState();
}

class _CommandSequencePageState extends State<CommandSequencePage> {
  List<CommandModel> _commands = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommands();

    // Auto connect when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      if (!socketService.isConnected) {
        socketService.connect();
      }
    });
  }

  Future<void> _loadCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commandsJson = prefs.getString('robot_commands');

      if (commandsJson != null) {
        final List<dynamic> commandsList = json.decode(commandsJson);
        setState(() {
          _commands =
              commandsList.map((json) => CommandModel.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error loading commands: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commandsJson = json.encode(
        _commands.map((cmd) => cmd.toJson()).toList(),
      );
      await prefs.setString('robot_commands', commandsJson);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Urutan perintah berhasil disimpan!',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan perintah: $e',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _runCommands() {
    if (_commands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada perintah untuk dijalankan!',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final socketService = Provider.of<SocketService>(context, listen: false);
    final commandsData = _commands.map((cmd) => cmd.toJson()).toList();

    socketService.sendCommandSequence(commandsData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Menjalankan ${_commands.length} perintah...',
          style: GoogleFonts.nunito(),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '📋 Susun Perintah',
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _saveCommands,
            icon: const Icon(Icons.save),
            tooltip: 'Simpan Urutan',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF81C784).withOpacity(0.1),
              const Color(0xFF4FC3F7).withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            // Connection status
            _buildConnectionStatus(),

            // Commands list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCommandsList(),
            ),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCommandDialog,
        backgroundColor: const Color(0xFF81C784),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Perintah',
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<SocketService>(
      builder: (context, socketService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: socketService.isConnected
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: socketService.isConnected ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    socketService.isConnected ? Icons.wifi : Icons.wifi_off,
                    color:
                        socketService.isConnected ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      socketService.isConnected
                          ? 'Robot Siap Menerima Perintah'
                          : 'Robot Tidak Terhubung',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: socketService.isConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandsList() {
    if (_commands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada perintah',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambah perintah',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _commands.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final command = _commands.removeAt(oldIndex);
          _commands.insert(newIndex, command);
        });
        HapticFeedback.lightImpact();
      },
      itemBuilder: (context, index) {
        final command = _commands[index];
        return _buildCommandCard(command, index);
      },
    );
  }

  Widget _buildCommandCard(CommandModel command, int index) {
    return Card(
      key: ValueKey('command_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCommandColor(command.type),
          child: Text(
            '${index + 1}',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(
              _getCommandIcon(command.type),
              color: _getCommandColor(command.type),
            ),
            const SizedBox(width: 8),
            Text(
              _getCommandDisplayName(command.type),
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durasi: ${command.duration}d',
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Kecepatan: ${command.speed}%',
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Maks. Jarak: ${command.max_distance}cm',
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _removeCommand(index),
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Hapus Perintah',
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveCommands,
              icon: const Icon(Icons.save),
              label: Text(
                'Simpan',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _commands.isNotEmpty ? _runCommands : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Jalankan',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCommandDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCommandDialog(
        onCommandAdded: (command) {
          setState(() {
            _commands.add(command);
          });
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _removeCommand(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus Perintah',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus perintah ini?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _commands.removeAt(index);
              });
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  IconData _getCommandIcon(String type) {
    switch (type) {
      case 'maju':
        return Icons.keyboard_arrow_up;
      case 'mundur':
        return Icons.keyboard_arrow_down;
      case 'kiri':
        return Icons.keyboard_arrow_left;
      case 'kanan':
        return Icons.keyboard_arrow_right;
      case 'berhenti':
        return Icons.stop;
      default:
        return Icons.help;
    }
  }

  Color _getCommandColor(String type) {
    switch (type) {
      case 'maju':
        return Colors.green;
      case 'mundur':
        return Colors.orange;
      case 'kiri':
        return Colors.blue;
      case 'kanan':
        return Colors.purple;
      case 'berhenti':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCommandDisplayName(String type) {
    switch (type) {
      case 'maju':
        return 'Maju';
      case 'mundur':
        return 'Mundur';
      case 'kiri':
        return 'Kiri';
      case 'kanan':
        return 'Kanan';
      case 'berhenti':
        return 'Berhenti';
      default:
        return type;
    }
  }
}

class AddCommandDialog extends StatefulWidget {
  final Function(CommandModel) onCommandAdded;

  const AddCommandDialog({
    super.key,
    required this.onCommandAdded,
  });

  @override
  State<AddCommandDialog> createState() => _AddCommandDialogState();
}

class _AddCommandDialogState extends State<AddCommandDialog> {
  String _selectedCommand = 'maju';
  double _duration = 2.0;
  double _speed = 50;
  double _max_distance = 10;

  final List<Map<String, dynamic>> _availableCommands = [
    {
      'value': 'maju',
      'label': 'Maju',
      'icon': Icons.keyboard_arrow_up,
      'color': Colors.green
    },
    {
      'value': 'mundur',
      'label': 'Mundur',
      'icon': Icons.keyboard_arrow_down,
      'color': Colors.orange
    },
    {
      'value': 'kiri',
      'label': 'Kiri',
      'icon': Icons.keyboard_arrow_left,
      'color': Colors.blue
    },
    {
      'value': 'kanan',
      'label': 'Kanan',
      'icon': Icons.keyboard_arrow_right,
      'color': Colors.purple
    },
    {
      'value': 'berhenti',
      'label': 'Berhenti',
      'icon': Icons.stop,
      'color': Colors.red
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Tambah Perintah Baru',
        style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Command selection
          Text(
            'Pilih Perintah:',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCommands.map((cmd) {
              final isSelected = _selectedCommand == cmd['value'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCommand = cmd['value'];
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cmd['color']
                        : cmd['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cmd['color'],
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cmd['icon'],
                        color: isSelected ? Colors.white : cmd['color'],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cmd['label'],
                        style: GoogleFonts.nunito(
                          color: isSelected ? Colors.white : cmd['color'],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Duration slider
          Text(
            'Durasi: ${_duration.toStringAsFixed(1)} detik',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: _duration,
            min: 0.5,
            max: 10.0,
            divisions: 19,
            onChanged: (value) {
              setState(() {
                _duration = value;
              });
            },
          ),

          const SizedBox(height: 20),

          // Speed slider
          Text(
            'Kecepatan: ${_speed.toStringAsFixed(0)}%',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: _speed,
            min: 0.0,
            max: 100.0,
            divisions: 50,
            onChanged: (value) {
              setState(() {
                _speed = value;
              });
            },
          ),

          const SizedBox(height: 20),

          // Speed slider
          Text(
            'Maksimal Jarak: ${_max_distance.toStringAsFixed(0)}cm',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: _max_distance,
            min: 0.0,
            max: 100.0,
            divisions: 50,
            onChanged: (value) {
              setState(() {
                _max_distance = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final command = CommandModel(
              type: _selectedCommand,
              duration: _duration,
              speed: _speed.toInt(),
              max_distance: _max_distance.toInt(),
            );
            widget.onCommandAdded(command);
            Navigator.pop(context);
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
