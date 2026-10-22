import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../services/mushaf_service.dart';
import '../services/storage_service.dart';
import 'reading_screen.dart';

/// قائمة السور: نقطة الدخول لوضع «اقرأ وصحّح».
class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final TextEditingController _search = TextEditingController();
  Set<int> _cached = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCached() async {
    final c = await MushafService.cachedSurahs();
    if (mounted) setState(() => _cached = c);
  }

  Future<void> _open(int surah, {int? ayah}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReadingScreen(surahNumber: surah, jumpToAyah: ayah)),
    );
    if (mounted) {
      setState(() {});
      _loadCached();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StorageService.instance;
    final scheme = Theme.of(context).colorScheme;
    final last = store.lastPosition;

    final q = _search.text.trim();
    final numbers = <int>[
      for (var i = 1; i <= 114; i++)
        if (q.isEmpty || surahName(i).contains(q) || i.toString() == q) i,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('اقرأ وصحّح تلاوتك')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ابحث باسم السورة أو رقمها',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          if (last != null && q.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Card(
                color: scheme.primaryContainer,
                child: ListTile(
                  leading: Icon(Icons.bookmark, color: scheme.primary),
                  title: Text('متابعة من سورة ${surahName(last.$1)}'),
                  subtitle: Text('الآية ${arabicDigits(last.$2)}'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _open(last.$1, ayah: last.$2),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: numbers.length,
              itemBuilder: (context, i) {
                final n = numbers[i];
                final count = surahAyahCount(n);
                final mastered = store.masteredAyat(n, count);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _open(n),
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        n.toString(),
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('سورة ${surahName(n)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                    subtitle: Text(
                      mastered == 0
                          ? '$count آية'
                          : '$count آية  •  أتقنت $mastered',
                    ),
                    trailing: _cached.contains(n)
                        ? Tooltip(
                            message: 'محفوظة للعمل دون اتصال',
                            child: Icon(Icons.download_done, color: Colors.green.shade700),
                          )
                        : const Icon(Icons.cloud_download_outlined, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
