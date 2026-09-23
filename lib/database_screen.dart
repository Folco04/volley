import 'package:flutter/material.dart';
import 'catalogo.dart';
import 'database_helper.dart';
import 'theme.dart';
import 'widgets/puzzle_piece.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<Esercizio> _esercizi = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final list = await DatabaseHelper.instance.getTuttiEsercizi();
    if (!mounted) return;
    setState(() => _esercizi = list);
  }

  List<Esercizio> get _filtrati {
    if (_query.trim().isEmpty) return _esercizi;
    final q = _query.toLowerCase();
    return _esercizi
        .where(
          (e) =>
              e.titolo.toLowerCase().contains(q) ||
              e.tipologia.toLowerCase().contains(q) ||
              e.categoria.toLowerCase().contains(q) ||
              e.ruolo.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _nuovo() async {
    final titoloCtrl = TextEditingController();
    final durataCtrl = TextEditingController(text: '10');
    String tipologia = Catalogo.tipologie.first;
    String categoria = Catalogo.categorie.first;
    String ruolo = Catalogo.ruoli.last;
    int colorIndex = _esercizi.length % AppColors.puzzle.length;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width - 40;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setM) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nuovo esercizio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titoloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titolo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: durataCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Durata (minuti)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownMenu<String>(
                      initialSelection: tipologia,
                      label: const Text('Tipologia'),
                      width: w,
                      dropdownMenuEntries: [
                        for (final t in Catalogo.tipologie)
                          DropdownMenuEntry(value: t, label: t),
                      ],
                      onSelected: (v) => setM(() => tipologia = v ?? tipologia),
                    ),
                    const SizedBox(height: 10),
                    DropdownMenu<String>(
                      initialSelection: categoria,
                      label: const Text('Categoria'),
                      width: w,
                      dropdownMenuEntries: [
                        for (final t in Catalogo.categorie)
                          DropdownMenuEntry(value: t, label: t),
                      ],
                      onSelected: (v) => setM(() => categoria = v ?? categoria),
                    ),
                    const SizedBox(height: 10),
                    DropdownMenu<String>(
                      initialSelection: ruolo,
                      label: const Text('Ruolo'),
                      width: w,
                      dropdownMenuEntries: [
                        for (final t in Catalogo.ruoli)
                          DropdownMenuEntry(value: t, label: t),
                      ],
                      onSelected: (v) => setM(() => ruolo = v ?? ruolo),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Colore pezzo (stesso in Fabbrica)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var i = 0; i < AppColors.puzzle.length; i++)
                          GestureDetector(
                            onTap: () => setM(() => colorIndex = i),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.puzzle[i],
                              child: colorIndex == i
                                  ? const Icon(Icons.check, size: 16)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.pinkDeep,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Salva esercizio'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (ok != true) return;
    final titolo = titoloCtrl.text.trim();
    if (titolo.isEmpty) return;
    await DatabaseHelper.instance.inserisciEsercizio(
      Esercizio(
        titolo: titolo,
        durataMinuti: int.tryParse(durataCtrl.text) ?? 10,
        tipologia: tipologia,
        categoria: categoria,
        ruolo: ruolo,
        colorIndex: colorIndex,
      ),
    );
    await _carica();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtrati;
    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.ink,
        onPressed: _nuovo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.pink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Database',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(Icons.search_rounded),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cerca esercizio…',
                  filled: true,
                  fillColor: AppColors.white,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.95,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final es = list[i];
                  return PuzzlePiece(
                    color: AppColors.puzzleAt(es.colorIndex),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          es.titolo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${es.tipologia} · ${es.categoria}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          es.ruolo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink.withValues(alpha: 0.45),
                          ),
                        ),
                        Text(
                          '${es.durataMinuti} minuti',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
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
