import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart';
import 'theme.dart';
import 'widgets/puzzle_piece.dart';

class CalendarioScreen extends StatefulWidget {
  final int refreshToken;
  const CalendarioScreen({super.key, this.refreshToken = 0});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _giornoSelezionato = DateTime.now();
  DateTime _giornoFocalizzato = DateTime.now();
  List<Allenamento> _allenamentiDelGiorno = [];
  Set<DateTime> _giorniPieni = {};

  @override
  void initState() {
    super.initState();
    _ricarica();
  }

  @override
  void didUpdateWidget(covariant CalendarioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _ricarica();
  }

  Future<void> _ricarica() async {
    await _caricaMarker();
    await _caricaAllenamentiDelGiorno(_giornoSelezionato);
  }

  String _iso(DateTime g) =>
      '${g.year.toString().padLeft(4, '0')}-${g.month.toString().padLeft(2, '0')}-${g.day.toString().padLeft(2, '0')}';

  Future<void> _caricaMarker() async {
    final giorni = await DatabaseHelper.instance.getGiorniConAllenamento();
    if (!mounted) return;
    setState(() => _giorniPieni = giorni);
  }

  Future<void> _caricaAllenamentiDelGiorno(DateTime giorno) async {
    final allenamenti = await DatabaseHelper.instance.getAllenamentiDelGiorno(
      _iso(giorno),
    );
    if (!mounted) return;
    setState(() => _allenamentiDelGiorno = allenamenti);
  }

  Future<void> _elimina(Allenamento a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare l\'allenamento?'),
        content: const Text(
          'La seduta sparirà dal calendario. Questa azione non si può annullare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true || a.id == null) return;
    await DatabaseHelper.instance.eliminaAllenamento(a.id!);
    await _ricarica();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Allenamento eliminato'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> _scaletta(Allenamento a) {
    try {
      return (jsonDecode(a.scalettaJson) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.pink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Calendario Settimanale',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _giornoFocalizzato,
                selectedDayPredicate: (day) =>
                    isSameDay(_giornoSelezionato, day),
                eventLoader: (day) {
                  return _giorniPieni.any((g) => isSameDay(g, day))
                      ? ['seduta']
                      : [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _giornoSelezionato = selectedDay;
                    _giornoFocalizzato = focusedDay;
                  });
                  _caricaAllenamentiDelGiorno(selectedDay);
                },
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.pinkDeep,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.sky.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Color(0xFF86DC82),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _allenamentiDelGiorno.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun allenamento in questo giorno.\nCostruiscilo in Fabbrica e salvalo qui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: _allenamentiDelGiorno.length,
                      itemBuilder: (context, index) {
                        final allenamento = _allenamentiDelGiorno[index];
                        final scaletta = _scaletta(allenamento);
                        return Dismissible(
                          key: ValueKey('all-${allenamento.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _elimina(allenamento);
                            return false;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                          ),
                          child: _SedutaCard(
                            allenamento: allenamento,
                            scaletta: scaletta,
                            onDelete: () => _elimina(allenamento),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SedutaCard extends StatelessWidget {
  final Allenamento allenamento;
  final List<Map<String, dynamic>> scaletta;
  final VoidCallback onDelete;

  const _SedutaCard({
    required this.allenamento,
    required this.scaletta,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    allenamento.titolo ?? 'Seduta',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Elimina allenamento',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < scaletta.length; i++)
            Builder(
              builder: (context) {
                final blocco = scaletta[i];
                final raw = blocco['esercizi'];
                final esercizi = <Esercizio>[];
                if (raw is List) {
                  for (final e in raw) {
                    esercizi.add(Esercizio.fromJson(e));
                  }
                }
                final durata = blocco['durata'] ?? 10;
                final altezza = (durata is int)
                    ? (durata * 4.4).clamp(92.0, 160.0)
                    : 100.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 52,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Text(
                            '${blocco['ora_inizio'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, i == 0 ? 0 : -kPuzzleKnob + 6),
                          child: SizedBox(
                            height: altezza,
                            child: Row(
                              children: [
                                for (var j = 0; j < esercizi.length; j++)
                                  Expanded(
                                    child: PuzzlePiece(
                                      color: AppColors.puzzleAt(
                                        esercizi[j].colorIndex,
                                      ),
                                      top: i == 0
                                          ? PuzzleSide.flat
                                          : PuzzleSide.socket,
                                      bottom: PuzzleSide.tab,
                                      left: j > 0
                                          ? PuzzleSide.socket
                                          : PuzzleSide.flat,
                                      right: PuzzleSide.tab,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            esercizi[j].titolo,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${blocco['ora_inizio']} · ${blocco['durata']} min',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink.withValues(alpha: 
                                                0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
