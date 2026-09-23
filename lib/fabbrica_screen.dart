import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'catalogo.dart';
import 'database_helper.dart';
import 'theme.dart';
import 'widgets/puzzle_piece.dart';

class FabbricaScreen extends StatefulWidget {
  final int refreshToken;
  const FabbricaScreen({super.key, this.refreshToken = 0});

  @override
  State<FabbricaScreen> createState() => _FabbricaScreenState();
}

class _FabbricaScreenState extends State<FabbricaScreen> {
  List<Esercizio> _disponibili = [];
  final List<List<Esercizio>> _timeline = [];
  DateTime _inizio = DateTime(2024, 1, 1, 18, 0);

  final Set<String> _filtroTipologie = {};
  final Set<String> _filtroCategorie = {};
  final Set<String> _filtroRuoli = {};

  @override
  void initState() {
    super.initState();
    _caricaEsercizi();
  }

  @override
  void didUpdateWidget(covariant FabbricaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _caricaEsercizi();
    }
  }

  Future<void> _caricaEsercizi() async {
    final esercizi = await DatabaseHelper.instance.getTuttiEsercizi();
    if (!mounted) return;
    setState(() => _disponibili = esercizi);
  }

  bool get _filtriAttivi =>
      _filtroTipologie.isNotEmpty ||
      _filtroCategorie.isNotEmpty ||
      _filtroRuoli.isNotEmpty;

  List<Esercizio> get _filtrati {
    return _disponibili.where((e) {
      if (_filtroTipologie.isNotEmpty &&
          !_filtroTipologie.contains(e.tipologia)) {
        return false;
      }
      if (_filtroCategorie.isNotEmpty &&
          !_filtroCategorie.contains(e.categoria)) {
        return false;
      }
      if (_filtroRuoli.isNotEmpty) {
        final okRuolo =
            _filtroRuoli.contains(e.ruolo) || e.ruolo == 'Tutti';
        if (!okRuolo) return false;
      }
      return true;
    }).toList();
  }

  void _resetFiltri() {
    setState(() {
      _filtroTipologie.clear();
      _filtroCategorie.clear();
      _filtroRuoli.clear();
    });
  }

  void _inserisciInMezzo(int index, Esercizio es) {
    setState(() => _timeline.insert(index, [es.copia()]));
  }

  void _aggiungiInFondo(Esercizio es) {
    setState(() => _timeline.add([es.copia()]));
  }

  void _affianca(int index, Esercizio es) {
    if (_timeline[index].length >= 2) return;
    setState(() => _timeline[index].add(es.copia()));
  }

  Future<void> _modificaDurata(Esercizio es) async {
    final ctrl = TextEditingController(text: '${es.durataMinuti}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Durata esercizio'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Minuti',
              suffixText: 'min',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              Navigator.pop(ctx, int.tryParse(v));
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.pinkDeep,
              ),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (result == null) return;
    setState(() => es.durataMinuti = result.clamp(1, 180));
  }

  Future<void> _apriFiltri() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setM) {
            Widget sezione(String titolo, List<String> opzioni, Set<String> sel) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titolo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final o in opzioni)
                        FilterChip(
                          label: Text(o),
                          selected: sel.contains(o),
                          selectedColor: AppColors.pink,
                          onSelected: (v) {
                            setM(() {
                              if (v) {
                                sel.add(o);
                              } else {
                                sel.remove(o);
                              }
                            });
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filtri pezzi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setM(_resetFiltri);
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  sezione('Tipologia', Catalogo.tipologie, _filtroTipologie),
                  sezione('Categoria', Catalogo.categorie, _filtroCategorie),
                  sezione('Ruolo', Catalogo.ruoli, _filtroRuoli),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pinkDeep,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Vedi ${_filtrati.length} esercizi',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _salvaAllenamento() async {
    if (_timeline.isEmpty) return;

    DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2032),
      helpText: 'Scegli il giorno della seduta',
    );
    if (data == null || !mounted) return;

    final ora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _inizio.hour, minute: _inizio.minute),
      helpText: 'Orario di inizio',
    );
    if (ora == null || !mounted) return;

    DateTime orarioCorrente = DateTime(
      data.year,
      data.month,
      data.day,
      ora.hour,
      ora.minute,
    );
    _inizio = orarioCorrente;

    final scalettaConOrari = <Map<String, dynamic>>[];
    for (final riga in _timeline) {
      final maxDurataRiga = riga.fold<int>(
        0,
        (max, e) => e.durataMinuti > max ? e.durataMinuti : max,
      );
      final oraInizioStr =
          '${orarioCorrente.hour.toString().padLeft(2, '0')}:${orarioCorrente.minute.toString().padLeft(2, '0')}';
      scalettaConOrari.add({
        'ora_inizio': oraInizioStr,
        'esercizi': riga.map((e) => e.toJson()).toList(),
        'durata': maxDurataRiga,
      });
      orarioCorrente = orarioCorrente.add(Duration(minutes: maxDurataRiga));
    }

    final dataIso =
        '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

    await DatabaseHelper.instance.salvaAllenamento(
      Allenamento(
        data: dataIso,
        scalettaJson: jsonEncode(scalettaConOrari),
        titolo: 'Seduta ${ora.format(context)}',
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Allenamento salvato per il $dataIso'),
        backgroundColor: const Color(0xFF5BBF6A),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(_timeline.clear);
  }

  Widget _slotInserisci(int index) {
    return DragTarget<Esercizio>(
      onAcceptWithDetails: (d) => _inserisciInMezzo(index, d.data),
      builder: (context, candidate, _) {
        final hot = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: hot ? 72 : 40,
          margin: const EdgeInsets.fromLTRB(36, 6, 36, 6),
          decoration: BoxDecoration(
            color: hot
                ? AppColors.pink.withValues(alpha: 0.45)
                : AppColors.creamDark.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hot ? AppColors.pinkDeep : const Color(0xFFD4CBBE),
              width: hot ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              hot ? 'Rilascia per inserire qui' : 'Trascina qui per inserire',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: hot ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibili = _filtrati;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Fabbrica',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _timeline.isEmpty ? null : _salvaAllenamento,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Salva'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.pinkDeep,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                itemCount: _timeline.isEmpty ? 1 : _timeline.length + 1,
                itemBuilder: (context, index) {
                  if (index == _timeline.length) {
                    return DragTarget<Esercizio>(
                      onAcceptWithDetails: (d) => _aggiungiInFondo(d.data),
                      builder: (context, candidateData, _) {
                        final hovering = candidateData.isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: hovering ? 110 : 88,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 8,
                          ),
                          child: PuzzlePiece(
                            color: hovering
                                ? AppColors.pink
                                : const Color(0xFFD9D0C4),
                            outline: true,
                            top: _timeline.isEmpty
                                ? PuzzleSide.flat
                                : PuzzleSide.socket,
                            bottom: PuzzleSide.flat,
                            left: PuzzleSide.flat,
                            right: PuzzleSide.flat,
                            child: Center(
                              child: Text(
                                _timeline.isEmpty
                                    ? 'Trascina qui il primo esercizio'
                                    : 'Aggiungi in fondo',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  final riga = _timeline[index];
                  final maxDurata = riga.fold<int>(
                    0,
                    (max, e) => e.durataMinuti > max ? e.durataMinuti : max,
                  );
                  final altezza = (maxDurata * 5.2).clamp(120.0, 230.0);
                  final topSide = index == 0
                      ? PuzzleSide.flat
                      : PuzzleSide.socket;
                  final bottomSide = PuzzleSide.tab;

                  return Column(
                    children: [
                      if (index != 0) _slotInserisci(index),
                      DragTarget<Esercizio>(
                        onAcceptWithDetails: (d) => _affianca(index, d.data),
                        builder: (context, candidate, _) {
                          return SizedBox(
                            height: altezza,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < riga.length; i++)
                                  Expanded(
                                    child: ExercisePuzzleTile(
                                      esercizio: riga[i],
                                      colore: AppColors.puzzleAt(
                                        riga[i].colorIndex,
                                      ),
                                      top: topSide,
                                      bottom: bottomSide,
                                      left: i > 0
                                          ? PuzzleSide.socket
                                          : PuzzleSide.flat,
                                      right: PuzzleSide.tab,
                                      onEditDurata: () =>
                                          _modificaDurata(riga[i]),
                                      onDelete: () => setState(() {
                                        riga.removeAt(i);
                                        if (riga.isEmpty) {
                                          _timeline.removeAt(index);
                                        }
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              height: 168,
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Filtri',
                          onPressed: _apriFiltri,
                          style: IconButton.styleFrom(
                            backgroundColor: _filtriAttivi
                                ? AppColors.pink
                                : AppColors.creamDark,
                          ),
                          icon: Badge(
                            isLabelVisible: _filtriAttivi,
                            label: Text(
                              '${_filtroTipologie.length + _filtroCategorie.length + _filtroRuoli.length}',
                            ),
                            child: const Icon(Icons.filter_list_rounded),
                          ),
                        ),
                        if (_filtriAttivi)
                          TextButton(
                            onPressed: _resetFiltri,
                            child: const Text('Reset'),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            visibili.isEmpty
                                ? 'Nessun esercizio con questi filtri'
                                : 'Trascina i pezzi · ${visibili.length}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visibili.isEmpty
                        ? const Center(
                            child: Text(
                              'Prova Reset oppure cambia i filtri',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                            itemCount: visibili.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 4),
                            itemBuilder: (context, index) {
                              final es = visibili[index];
                              final colore = AppColors.puzzleAt(es.colorIndex);
                              final mini = SizedBox(
                                width: 112,
                                height: 96,
                                child: MiniPuzzleChip(
                                  titolo: es.titolo,
                                  subtitle: '${es.durataMinuti} min',
                                  color: colore,
                                ),
                              );
                              return Draggable<Esercizio>(
                                data: es,
                                affinity: Axis.vertical,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: 120,
                                    height: 96,
                                    child: MiniPuzzleChip(
                                      titolo: es.titolo,
                                      subtitle: '${es.durataMinuti} min',
                                      color: colore,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.28,
                                  child: mini,
                                ),
                                child: mini,
                              );
                            },
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

class ExercisePuzzleTile extends StatelessWidget {
  final Esercizio esercizio;
  final Color colore;
  final PuzzleSide top, bottom, left, right;
  final VoidCallback onEditDurata, onDelete;

  const ExercisePuzzleTile({
    super.key,
    required this.esercizio,
    required this.colore,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.onEditDurata,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.onPuzzle(colore);
    return PuzzlePiece(
      color: colore,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          esercizio.titolo,
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.close_rounded,
                          color: ink.withValues(alpha: 0.35),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${esercizio.tipologia} · ${esercizio.categoria}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onEditDurata,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${esercizio.durataMinuti} min',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
