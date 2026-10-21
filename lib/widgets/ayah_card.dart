import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../models/question.dart';
import '../services/connectivity_service.dart';
import '../services/quran_service.dart';

/// بطاقة تعرض العبارة القرآنية المرتبطة بالسؤال، مع:
///  • عرض الآية كاملة (من الإنترنت، ثم تُخزَّن للعمل دون اتصال)
///  • الاستماع لتلاوتها (بث، أو ملف محمّل مسبقاً دون اتصال)
class AyahCard extends StatefulWidget {
  const AyahCard({super.key, required this.question});

  final Question question;

  @override
  State<AyahCard> createState() => _AyahCardState();
}

class _AyahCardState extends State<AyahCard> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _sub;
  bool _playing = false;
  bool _loadingAudio = false;
  bool _loadingText = false;
  String? _fullAyah;
  String? _message;

  Question get q => widget.question;

  @override
  void initState() {
    super.initState();
    _sub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s == PlayerState.playing);
    });
    // إن كانت الآية مخزنة محلياً نعرضها مباشرة دون انتظار
    if (q.hasAyahRef) _loadText(silent: true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadText({bool silent = false}) async {
    if (!q.hasAyahRef) return;
    if (!silent) setState(() => _loadingText = true);
    final text = await QuranService.getAyahText(q.surah!, q.ayah!);
    if (!mounted) return;
    setState(() {
      _loadingText = false;
      if (text != null) {
        _fullAyah = text;
        _message = null;
      } else if (!silent) {
        _message = 'الآية الكاملة غير محفوظة. اتصل بالإنترنت لعرضها وحفظها.';
      }
    });
  }

  Future<void> _toggleAudio() async {
    if (_playing) {
      await _player.stop();
      return;
    }
    setState(() {
      _loadingAudio = true;
      _message = null;
    });
    try {
      final downloaded = await QuranService.isAudioDownloaded(q.surah!, q.ayah!);
      if (!downloaded && !await ConnectivityService.isOnline()) {
        if (!mounted) return;
        setState(() {
          _loadingAudio = false;
          _message = 'لا يوجد اتصال. حمّل الصوتيات من الإعدادات للاستماع دون إنترنت.';
        });
        return;
      }
      final source = await QuranService.audioSource(q.surah!, q.ayah!);
      await _player.play(source);
      if (!mounted) return;
      setState(() => _loadingAudio = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingAudio = false;
        _message = 'تعذّر تشغيل الصوت.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phrase = q.phrase;
    if (phrase == null && !q.hasAyahRef) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9C79A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (phrase != null)
            Text(
              phrase,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, height: 1.9, color: Color(0xFF0B3D2E)),
            ),
          if (q.hasAyahRef) ...[
            Text(
              'سورة ${surahName(q.surah!)} - الآية ${q.ayah}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.outline),
            ),
            if (_fullAyah != null) ...[
              const Divider(height: 18),
              Text(
                _fullAyah!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, height: 2.0),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadingAudio ? null : _toggleAudio,
                  icon: _loadingAudio
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_playing ? Icons.stop : Icons.play_arrow),
                  label: Text(_playing ? 'إيقاف' : 'استمع'),
                ),
                if (_fullAyah == null)
                  OutlinedButton.icon(
                    onPressed: _loadingText ? null : () => _loadText(),
                    icon: _loadingText
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.menu_book),
                    label: const Text('الآية كاملة'),
                  ),
              ],
            ),
          ],
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: scheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
