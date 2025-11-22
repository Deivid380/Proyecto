import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io'; // Import for Platform checks
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // New import

import '../models/product.dart';
import '../models/sale.dart';
import 'package:quicksale_pos/models/user.dart';
import 'package:quicksale_pos/models/cliente_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal() {
    // Initialize FFI for desktop platforms only
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quicksale_pos.db');
    return await openDatabase(
      path,
      version: 8, // Incrementado a 8
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL,
        stock INTEGER,
        barcode TEXT UNIQUE,
        imageUrl TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        totalAmount REAL,
        userId INTEGER,
        clienteId INTEGER,
        clientName TEXT, // New column
        clientPhone TEXT, // New column
        paymentMethod TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER,
        productId INTEGER,
        productName TEXT,
        quantity INTEGER,
        price REAL,
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT,
        status TEXT DEFAULT 'active'
      )
    ''');
    await db.execute('''
      CREATE TABLE clientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        telefono TEXT,
        deudaActual REAL
      )
    ''');

    await db.insert('users', {
      'username': 'admin',
      'password': 'admin',
      'role': 'admin',
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN status TEXT DEFAULT 'active'",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE products ADD COLUMN imageUrl TEXT",
      );
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE clientes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT,
          telefono TEXT,
          deudaActual REAL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE sales ADD COLUMN userId INTEGER');
    }
    if (oldVersion < 6) {
      // Check if the column already exists before adding it
      List<Map> columns = await db.rawQuery("PRAGMA table_info(sales)");
      bool clienteIdExists = columns.any((column) => column['name'] == 'clienteId');
      if (!clienteIdExists) {
        await db.execute('ALTER TABLE sales ADD COLUMN clienteId INTEGER');
      }
    }
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE sales ADD COLUMN paymentMethod TEXT");
    }
    if (oldVersion < 8) { // New migration for clientName and clientPhone
      List<Map> columns = await db.rawQuery("PRAGMA table_info(sales)");
      bool clientNameExists = columns.any((column) => column['name'] == 'clientName');
      if (!clientNameExists) {
        await db.execute("ALTER TABLE sales ADD COLUMN clientName TEXT");
      }
      bool clientPhoneExists = columns.any((column) => column['name'] == 'clientPhone');
      if (!clientPhoneExists) {
        await db.execute("ALTER TABLE sales ADD COLUMN clientPhone TEXT");
      }
    }
  }

  // --- Métodos para Clientes ---
  Future<int> insertCliente(Cliente cliente) async {
    Database db = await database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> getAllClientes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('clientes');
    return List.generate(maps.length, (i) {
      return Cliente.fromMap(maps[i]);
    });
  }

  Future<int> updateCliente(Cliente cliente) async {
    Database db = await database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<int> deleteCliente(int id) async {
    Database db = await database;
    return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Métodos para Usuarios ---
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  Future<User?> findUserByUsernameAndPassword(
      String username, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> doesUserExist(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty;
  }

  Future<int> updateUser(User user) async {
    Database db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- Métodos para Productos ---
  Future<int> insertProduct(Product product) async {
    Database db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    Database db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> updateProductStock(int productId, int newStock) async {
    Database db = await database;
    return await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<int> deleteProduct(int id) async {
    Database db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Métodos para Ventas ---
  Future<int> createSale(
    List<dynamic> cart,
    int userId, {
    int? clienteId,
    String? clientName,
    String? clientPhone,
    String? paymentMethod,
  }) async {
    Database db = await database;
    int saleId = 0;
    await db.transaction((txn) async {
      double totalAmount = cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
      saleId = await txn.insert('sales', {
        'date': DateTime.now().toIso8601String(),
        'totalAmount': totalAmount,
        'userId': userId,
        'clienteId': clienteId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'paymentMethod': paymentMethod,
      });

      for (var item in cart) {
        await txn.insert('sale_items', {
          'saleId': saleId,
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'price': item.product.price,
        });
        // Actualizar stock del producto
        Product currentProduct = item.product;
        if (currentProduct.stock >= item.quantity) {
          await txn.update(
            'products',
            {'stock': currentProduct.stock - item.quantity},
            where: 'id = ?',
            whereArgs: [currentProduct.id],
          );
        }
      }
    });
    return saleId;
  }

  Future<Product?> getProductById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Sale>> getAllSales({int? userId}) async {
    Database db = await database;
    List<Map<String, dynamic>> maps;
    if (userId != null && userId != 0) { // Asumiendo que 0 es para 'Todos'
      maps = await db.query(
        'sales',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
    } else {
      maps = await db.query(
        'sales',
        orderBy: 'date DESC',
      );
    }
    return List.generate(maps.length, (i) {
      return Sale.fromMap(maps[i]);
    });
  }

  Future<List<Sale>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
    {int? userId}
  ) async {
    Database db = await database;
    String whereClause = 'date BETWEEN ? AND ?';
    List<dynamic> whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];

    if (userId != null && userId != 0) { // 0 es el valor para "Todos los usuarios"
      whereClause += ' AND userId = ?';
      whereArgs.add(userId);
    }

    List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Sale.fromMap(maps[i]);
    });
  }

  Future<List<Map<String, dynamic>>> getSaleDetails(int saleId) async {
    Database db = await database;
    return await db.query(
      'sale_items',
      where: 'saleId = ?',
      whereArgs: [saleId],
    );
  }

  Future<int> deleteSale(int id) async {
    Database db = await database;
    return await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT productName as name, SUM(quantity) as total_quantity
      FROM sale_items
      GROUP BY productName
      ORDER BY total_quantity DESC
      LIMIT 5
    ''');
    return result;
  }

  Future<Map<String, dynamic>> getSalesSummary(
    DateTime startDate,
    DateTime endDate, {
    int? userId,
  }) async {
    Database db = await database;
    final adjustedEndDate = endDate.add(const Duration(days: 1));

    String whereClause = 'date >= ? AND date < ?';
    List<dynamic> whereArgs = [
      startDate.toIso8601String(),
      adjustedEndDate.toIso8601String()
    ];

    if (userId != null && userId != 0) {
      whereClause += ' AND userId = ?';
      whereArgs.add(userId);
    }

    final totalSalesResult = await db.rawQuery('''
      SELECT SUM(totalAmount) as total
      FROM sales
      WHERE $whereClause
    ''', whereArgs);

    final topProductResult = await db.rawQuery('''
      SELECT productName as name, SUM(quantity) as total_quantity
      FROM sale_items
      WHERE saleId IN (SELECT id FROM sales WHERE $whereClause)
      GROUP BY productName
      ORDER BY total_quantity DESC
      LIMIT 1
    ''', whereArgs);

    return {
      'totalSales': totalSalesResult.first['total'] ?? 0.0,
      'topProduct': topProductResult.isNotEmpty ? topProductResult.first : null,
    };
  }

  Future<List<Map<String, dynamic>>> getDailySalesForLastWeek({int? userId}) async {
    Database db = await database;
    final today = DateTime.now();
    final List<Map<String, dynamic>> salesByDay = [];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      String whereClause = 'date >= ? AND date < ?';
      List<dynamic> whereArgs = [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String()
      ];

      if (userId != null && userId != 0) {
        whereClause += ' AND userId = ?';
        whereArgs.add(userId);
      }

      final result = await db.rawQuery('''
        SELECT SUM(totalAmount) as total
        FROM sales
        WHERE $whereClause
      ''', whereArgs);

      salesByDay.add({
        'date': startOfDay,
        'total': result.first['total'] ?? 0.0,
      });
    }
    return salesByDay;
  }

  Future<List<User>> fetchUsersForReports() async {
    final users = await getAllUsers();
    // Añadimos una opción para ver los reportes de todos los usuarios
    users.insert(
      0,
      User(id: 0, username: 'Todos los usuarios', password: '', role: ''),
    );
    return users;
  }
}