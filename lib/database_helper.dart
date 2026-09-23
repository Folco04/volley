import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Esercizio {
  final int? id;
  final String titolo;
  int durataMinuti;
  final String tipologia;
  final String categoria;
  final String ruolo;
  final int colorIndex;

  Esercizio({
    this.id,
    required this.titolo,
    required this.durataMinuti,
    required this.tipologia,
    required this.categoria,
    required this.ruolo,
    this.colorIndex = 0,
  });

  Esercizio copia({int? durataMinuti}) => Esercizio(
    id: id,
    titolo: titolo,
    durataMinuti: durataMinuti ?? this.durataMinuti,
    tipologia: tipologia,
    categoria: categoria,
    ruolo: ruolo,
    colorIndex: colorIndex,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'titolo': titolo,
    'durataMinuti': durataMinuti,
    'tipologia': tipologia,
    'categoria': categoria,
    'ruolo': ruolo,
    'colorIndex': colorIndex,
  };

  Map<String, dynamic> toJson() => {
    'titolo': titolo,
    'durataMinuti': durataMinuti,
    'tipologia': tipologia,
    'categoria': categoria,
    'ruolo': ruolo,
    'colorIndex': colorIndex,
  };

  factory Esercizio.fromMap(Map<String, dynamic> map) => Esercizio(
    id: map['id'] as int?,
    titolo: map['titolo'] as String,
    durataMinuti: map['durataMinuti'] as int,
    tipologia: (map['tipologia'] as String?) ?? 'Globale',
    categoria:
        (map['categoria'] as String?) ??
        (map['fondamentale'] as String?) ??
        'Palleggio',
    ruolo: (map['ruolo'] as String?) ?? 'Tutti',
    colorIndex: (map['colorIndex'] as int?) ?? 0,
  );

  factory Esercizio.fromJson(dynamic raw) {
    if (raw is String) {
      return Esercizio(
        titolo: raw,
        durataMinuti: 10,
        tipologia: 'Globale',
        categoria: 'Palleggio',
        ruolo: 'Tutti',
        colorIndex: raw.length % 6,
      );
    }
    final map = Map<String, dynamic>.from(raw as Map);
    return Esercizio(
      titolo: map['titolo'] as String,
      durataMinuti: (map['durataMinuti'] as int?) ?? 10,
      tipologia: (map['tipologia'] as String?) ?? 'Globale',
      categoria:
          (map['categoria'] as String?) ??
          (map['fondamentale'] as String?) ??
          'Palleggio',
      ruolo: (map['ruolo'] as String?) ?? 'Tutti',
      colorIndex: (map['colorIndex'] as int?) ?? 0,
    );
  }
}

class Allenamento {
  final int? id;
  final String data;
  final String scalettaJson;
  final String? titolo;

  Allenamento({
    this.id,
    required this.data,
    required this.scalettaJson,
    this.titolo,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'data': data,
    'scalettaJson': scalettaJson,
    'titolo': titolo,
  };

  factory Allenamento.fromMap(Map<String, dynamic> map) => Allenamento(
    id: map['id'] as int?,
    data: map['data'] as String,
    scalettaJson: map['scalettaJson'] as String,
    titolo: map['titolo'] as String?,
  );
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('volley_coach_v6.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE esercizi (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titolo TEXT NOT NULL,
      durataMinuti INTEGER NOT NULL,
      tipologia TEXT NOT NULL,
      categoria TEXT NOT NULL,
      ruolo TEXT NOT NULL,
      colorIndex INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE allenamenti (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data TEXT NOT NULL,
      scalettaJson TEXT NOT NULL,
      titolo TEXT
    )
    ''');

    final seed = [
      ['Attivazione', 15, 'Globale', 'Rice', 'Tutti', 0],
      ['Palleggio Analitico', 15, 'Analitico', 'Palleggio', 'Palleggio', 1],
      ['Attacco Sintetico', 20, 'Sintetico', 'Attacco', 'Opposto', 2],
      ['Globale 6v6', 15, 'Globale', 'Difesa', 'Tutti', 3],
      ['Battuta in Salto', 12, 'Analitico', 'Battuta', 'Banda', 4],
      ['Bagher a coppie', 10, 'Analitico', 'Bagher', 'Libero', 5],
      ['Difesa a 6', 12, 'Sintetico', 'Difesa', 'Tutti', 0],
      ['Terne attacco', 10, 'Sintetico', 'Attacco', 'Banda', 2],
      ['Muro a coppie', 10, 'Analitico', 'Muro', 'Centrale', 1],
    ];

    for (final row in seed) {
      await db.insert('esercizi', {
        'titolo': row[0],
        'durataMinuti': row[1],
        'tipologia': row[2],
        'categoria': row[3],
        'ruolo': row[4],
        'colorIndex': row[5],
      });
    }
  }

  Future<List<Esercizio>> getTuttiEsercizi() async {
    final db = await instance.database;
    final result = await db.query('esercizi', orderBy: 'id ASC');
    return result.map(Esercizio.fromMap).toList();
  }

  Future<int> contaEsercizi() async {
    final db = await instance.database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM esercizi');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> inserisciEsercizio(Esercizio e) async {
    final db = await instance.database;
    return db.insert('esercizi', e.toMap()..remove('id'));
  }

  Future<int> eliminaEsercizio(int id) async {
    final db = await instance.database;
    return db.delete('esercizi', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> salvaAllenamento(Allenamento allenamento) async {
    final db = await instance.database;
    return db.insert('allenamenti', allenamento.toMap()..remove('id'));
  }

  Future<int> eliminaAllenamento(int id) async {
    final db = await instance.database;
    return db.delete('allenamenti', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Allenamento>> getAllenamentiDelGiorno(String data) async {
    final db = await instance.database;
    final result = await db.query(
      'allenamenti',
      where: 'data = ?',
      whereArgs: [data],
      orderBy: 'id DESC',
    );
    return result.map(Allenamento.fromMap).toList();
  }

  Future<List<Allenamento>> getTuttiAllenamenti() async {
    final db = await instance.database;
    final result = await db.query('allenamenti', orderBy: 'data ASC');
    return result.map(Allenamento.fromMap).toList();
  }

  Future<int> contaAllenamenti() async {
    final db = await instance.database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM allenamenti');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<Set<DateTime>> getGiorniConAllenamento() async {
    final tutti = await getTuttiAllenamenti();
    return {for (final a in tutti) DateTime.parse(a.data)};
  }
}
