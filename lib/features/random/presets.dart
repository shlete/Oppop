import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 자주 쓰는 항목 목록. 룰렛 항목과 사다리 참가자에 함께 쓴다.
class Preset {
  const Preset({required this.name, required this.items, this.builtIn = false});

  final String name;
  final List<String> items;
  final bool builtIn;

  Map<String, Object> toJson() => {'name': name, 'items': items};

  factory Preset.fromJson(Map<String, dynamic> json) => Preset(
    name: json['name'] as String,
    items: (json['items'] as List).cast<String>(),
  );
}

const builtInPresets = [
  Preset(
    name: '점심 메뉴',
    items: ['한식', '중식', '일식', '양식', '분식', '편의점'],
    builtIn: true,
  ),
  Preset(
    name: '벌칙',
    items: ['커피 쏘기', '노래 한 소절', '애교 3초', '통과!'],
    builtIn: true,
  ),
  Preset(name: '순서 정하기', items: ['1번', '2번', '3번', '4번'], builtIn: true),
];

final presetsProvider = NotifierProvider<PresetsNotifier, List<Preset>>(
  PresetsNotifier.new,
);

/// 기본 프리셋 + 사용자가 저장한 프리셋 (기기에 저장).
class PresetsNotifier extends Notifier<List<Preset>> {
  static const _key = 'random.presets';

  @override
  List<Preset> build() {
    _load();
    return builtInPresets;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final saved = (jsonDecode(raw) as List).map(
      (e) => Preset.fromJson(e as Map<String, dynamic>),
    );
    state = [...builtInPresets, ...saved];
  }

  Future<void> save(String name, List<String> items) async {
    final user = [
      for (final p in state)
        if (!p.builtIn && p.name != name) p,
      Preset(name: name, items: items),
    ];
    state = [...builtInPresets, ...user];
    await _persist(user);
  }

  Future<void> remove(Preset preset) async {
    final user = [
      for (final p in state)
        if (!p.builtIn && p.name != preset.name) p,
    ];
    state = [...builtInPresets, ...user];
    await _persist(user);
  }

  Future<void> _persist(List<Preset> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final p in user) p.toJson()]));
  }
}
