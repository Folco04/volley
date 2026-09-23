import 'dart:convert';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  final int refreshToken;
  const HomeScreen({super.key, this.refreshToken = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _nAllenamenti = 0;
  int _nEsercizi = 0;
  Allenamento? _prossimo;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _carica();
  }

  Future<void> _carica() async {
    final nA = await DatabaseHelper.instance.contaAllenamenti();
    final nE = await DatabaseHelper.instance.contaEsercizi();
    final tutti = await DatabaseHelper.instance.getTuttiAllenamenti();
    final oggi = DateTime.now();
    final oggiKey =
        '${oggi.year.toString().padLeft(4, '0')}-${oggi.month.toString().padLeft(2, '0')}-${oggi.day.toString().padLeft(2, '0')}';
    Allenamento? next;
    for (final a in tutti) {
      if (a.data.compareTo(oggiKey) >= 0) {
        next = a;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _nAllenamenti = nA;
      _nEsercizi = nE;
      _prossimo = next;
    });
  }

  String _oraProssimo() {
    if (_prossimo == null) return '--:--';
    try {
      final scaletta = jsonDecode(_prossimo!.scalettaJson) as List;
      if (scaletta.isEmpty) return '--:--';
      return scaletta.first['ora_inizio'] as String? ?? '--:--';
    } catch (_) {
      return '--:--';
    }
  }

  String _giornoProssimo() {
    if (_prossimo == null) return 'Nessuna seduta';
    const giorni = [
      'Lunedì',
      'Martedì',
      'Mercoledì',
      'Giovedì',
      'Venerdì',
      'Sabato',
      'Domenica',
    ];
    final d = DateTime.parse(_prossimo!.data);
    return '${giorni[d.weekday - 1]} @ ${_oraProssimo()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: AppColors.pink,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.sports_volleyball, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ciao, Coach!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Allenamenti Creati',
                    value: '$_nAllenamenti',
                    child: const Icon(
                      Icons.sports_volleyball_rounded,
                      size: 42,
                      color: Color(0xFFE76F51),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Esercizi in Database',
                    value: '$_nEsercizi',
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 36,
                      color: Colors.orange.shade300,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prossimo Allenamento:',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _prossimo == null
                              ? 'Nessuna seduta'
                              : _giornoProssimo(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 30),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learning Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: CustomPaint(
                      painter: _BarsPainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Widget child;
  const _StatCard({
    required this.title,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              child,
            ],
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.pink,
      AppColors.mint,
      AppColors.peach,
      const Color(0xFFF5D24A),
      AppColors.sky,
    ];
    final vals = [0.45, 0.7, 0.55, 0.9, 0.4, 0.65, 0.5];
    final w = size.width / (vals.length * 1.8);
    for (var i = 0; i < vals.length; i++) {
      final h = size.height * vals[i];
      final x = i * (w * 1.8) + 8;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, w, h),
        const Radius.circular(8),
      );
      canvas.drawRRect(r, Paint()..color = colors[i % colors.length]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
