import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/user.dart'; // Importamos el modelo de usuario

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quicksale_pos.db');
    return await openDatabase(
      path,
      version: 2, // ¡Importante! Aumentamos la versión
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
        barcode TEXT UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        totalAmount REAL
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
    // Nueva tabla para usuarios
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT,
        status TEXT DEFAULT 'active'
      )
    ''');

    // Insertar usuario administrador por defecto
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin', // En una app real, esto debería ser un hash
      'role': 'admin',
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Si la base de datos vieja es versión 1, le añadimos la columna 'status'
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN status TEXT DEFAULT 'active'",
      );
    }
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
  Future<int> createSale(List<Product> cart) async {
    Database db = await database;
    int saleId = 0;
    await db.transaction((txn) async {
      double totalAmount = cart.fold(0, (sum, item) => sum + item.price);
      saleId = await txn.insert('sales', {
        'date': DateTime.now().toIso8601String(),
        'totalAmount': totalAmount,
      });

      for (var product in cart) {
        await txn.insert('sale_items', {
          'saleId': saleId,
          'productId': product.id,
          'productName': product.name,
          'quantity': 1, // Asumimos 1 por cada item en el carrito
          'price': product.price,
        });
        // Actualizar stock del producto
        Product? currentProduct = await getProductById(product.id!);
        if (currentProduct != null && currentProduct.stock > 0) {
          await updateProductStock(
            currentProduct.id!,
            currentProduct.stock - 1,
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

  Future<List<Sale>> getAllSales() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'sales',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Sale.fromMap(maps[i]);
    });
  }

  Future<List<Sale>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
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

  // --- Métodos para Usuarios ---
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<User?> findUserByUsernameAndPassword(
    String username,
    String password,
  ) async {
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

  Future<User?> getUserByUsername(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
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

  Future<List<User>> getAllUsers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }
}
