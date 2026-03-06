import 'package:flutter/material.dart';
import 'package:flutter_vless/flutter_vless.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FlutterVless _flutterVless;
  String _status = "Отключено";
  String _pingResult = "Не измерялся";
  final TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _flutterVless = FlutterVless(onStatusChanged: (status) {
      setState(() {
        _status = status;
      });
    });
    _init();
  }

  Future<void> _init() async {
    await _flutterVless.initializeVless(
      providerBundleIdentifier: 'com.example.myapp.VPNProvider',
      groupIdentifier: 'group.com.example.myapp',
    );
  }

  // Функция для подключения по ключу
  Future<void> _connect() async {
    final String link = _linkController.text;
    if (link.isEmpty) return;

    try {
      // Парсим ссылку
      final FlutterVlessURL parser = FlutterVless.parseFromURL(link);
      final String config = parser.getFullConfiguration();

      // Измеряем пинг
      final int delayMs = await _flutterVless.getServerDelay(config: config);
      setState(() {
        _pingResult = "Пинг: ${delayMs}ms";
      });

      // Запрашиваем разрешение на VPN
      final bool allowed = await _flutterVless.requestPermission();
      if (!allowed) return;

      // Подключаемся
      await _flutterVless.startVless(
        remark: parser.remark,
        config: config,
      );
    } catch (e) {
      setState(() {
        _status = "Ошибка: $e";
      });
    }
  }

  // Функция отключения
  Future<void> _disconnect() async {
    await _flutterVless.stopVless();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Мой VPN как Happ'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Поле для вставки ключа VLESS
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Вставьте VLESS ключ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              
              // Кнопки подключения/отключения
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _connect,
                    child: const Text('Подключиться'),
                  ),
                  ElevatedButton(
                    onPressed: _disconnect,
                    child: const Text('Отключиться'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Статус и пинг
              Text('Статус: $_status'),
              Text(_pingResult),
            ],
          ),
        ),
      ),
    );
  }
}
