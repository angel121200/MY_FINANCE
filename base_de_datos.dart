import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Clase para representar una transacción (Modelo de Datos)
class Transaction {
  final int? id;
  final String tipo;
  final String nombre;
  final double cantidad;
  final DateTime fecha;

  Transaction({
    this.id,
    required this.tipo,
    required this.nombre,
    required this.cantidad,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'nombre': nombre,
      'cantidad': cantidad,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      tipo: map['tipo'],
      nombre: map['nombre'],
      cantidad: map['cantidad'],
      fecha: DateTime.parse(map['fecha']),
    );
  }
}

// Clase para gestionar la base de datos (Tu DatabaseHelper)
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String documentsPath = await getDatabasesPath();
    String path = join(documentsPath, 'finances.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, tipo TEXT, nombre TEXT, cantidad REAL, fecha TEXT)',
    );
  }

  // Inserta una transacción
  Future<int> insertTransaction(Transaction transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  // Obtener todas las transacciones
  Future<List<Transaction>> getTransactions() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy:
          'fecha DESC', // Ordena por fecha descendente para obtener las últimas primero
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // --- NUEVO MÉTODO: Obtener la última transacción de un tipo específico ---
  Future<Transaction?> getLastTransactionByType(String tipo) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'tipo = ?', // Filtra por el tipo especificado
      whereArgs: [tipo],
      orderBy: 'fecha DESC', // Ordena por fecha descendente
      limit: 1, // Limita el resultado a 1 (la última)
    );

    if (maps.isNotEmpty) {
      return Transaction.fromMap(
        maps.first,
      ); // Devuelve la primera (la última por fecha)
    }
    return null; // Devuelve null si no hay transacciones de ese tipo
  }
  // --- FIN DEL NUEVO MÉTODO ---

  // Eliminar una transacción por ID
  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Eliminar transacciones por tipo (el método anterior, aún útil si lo necesitas)
  Future<int> deleteTransactionsByType(String tipo) async {
    Database db = await database;
    return await db.delete(
      'transactions',
      where: 'tipo = ?',
      whereArgs: [tipo],
    );
  }

  // Cerrar la base de datos (opcional)
  Future<void> close() async {
    Database db = await database;
    db.close();
  }
}
