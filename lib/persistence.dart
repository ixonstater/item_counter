import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'data_classes.dart';

class Persistence {
  final fileName = 'categories.sql';
  late Database db;
  bool snubCalls = false;

  Future<void> initDatabase() async {
    if (kIsWeb) {
      snubCalls = true;
      return;
    }
    WidgetsFlutterBinding.ensureInitialized();
    db = await openDatabase(
      join(await getDatabasesPath(), fileName),
      onCreate: ((db, version) async {
        runMigrations(db, version);
        await db.execute(
          'CREATE TABLE sub_categories ('
          'category_name TEXT, sub_category_name TEXT, count INTEGER, '
          'PRIMARY KEY(category_name, sub_category_name))',
        );

        await db.execute(
          'CREATE TABLE categories (category_name TEXT PRIMARY KEY)',
        );
      }),
      version: 1,
    );
  }

  void runMigrations(Database db, int version) {}

  Future<void> createCategory(String name) async {
    if (snubCalls) {
      return;
    }
    await db.execute(
      'INSERT INTO categories (category_name) VALUES (?)',
      [name],
    );
  }

  Future<void> deleteCategory(String name) async {
    if (snubCalls) {
      return;
    }
    await db.execute(
      'DELETE FROM categories WHERE category_name = ?',
      [name],
    );
    await db.execute(
      'DELETE FROM sub_categories WHERE category_name = ?',
      [name],
    );
  }

  Future<void> updateCategory(String oldName, String newName) async {
    if (snubCalls) {
      return;
    }
    await db.execute(
      'UPDATE categories SET category_name = ? WHERE category_name = ?',
      [newName, oldName],
    );

    await db.execute(
      'UPDATE sub_categories SET category_name = ? WHERE category_name = ?',
      [newName, oldName],
    );
  }

  Future<void> createSubCategory(
      String categoryName, String subCategoryName) async {
    if (snubCalls) {
      return;
    }
    await db.execute(
      'INSERT INTO sub_categories (category_name, sub_category_name, count) VALUES (?, ?, 0)',
      [categoryName, subCategoryName],
    );
  }

  Future<void> deleteSubCategory(
      String subCategoryName, String categoryName) async {
    if (snubCalls) {
      return;
    }
    await db.execute(
      'DELETE FROM sub_categories WHERE sub_category_name = ? AND category_name = ?',
      [subCategoryName, categoryName],
    );
  }

  Future<void> updateSubCategory(
      int count, String subCategoryName, String categoryName) async {
    if (snubCalls) {
      return;
    }
    await db.execute(
      'UPDATE sub_categories SET count = ? WHERE sub_category_name = ? and category_name = ?',
      [count, subCategoryName, categoryName],
    );
  }

  Future<List<Category>> readCategories() async {
    var categories = <Category>[];
    if (snubCalls) {
      return categories;
    }
    var categoryDb = await db.query(
      'categories',
      orderBy: 'category_name COLLATE NOCASE',
    );
    for (var category in categoryDb) {
      var subCategoriesDb = await db.query(
        'sub_categories',
        where: 'category_name = ?',
        whereArgs: [category['category_name']],
        orderBy: 'sub_category_name COLLATE NOCASE',
      );
      var subCategories = <SubCategory>[];
      for (var subCategory in subCategoriesDb) {
        var subCategoryObj = SubCategory(
          subCategory['sub_category_name'] as String,
        );
        subCategoryObj.count = subCategory['count'] as int;
        subCategories.add(subCategoryObj);
      }

      categories.add(
        Category(
          category['category_name'] as String,
          subCategories,
        ),
      );
    }
    return categories;
  }
}
