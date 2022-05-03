import 'package:flutter/material.dart';
import 'package:presentation/consolidated_view.dart';
import 'package:presentation/persistence.dart';
import 'data_classes.dart';

void main() async {
  var db = Persistence();
  await db.initDatabase();
  runApp(MyApp(db));
}

class MyApp extends StatelessWidget {
  final Persistence db;
  const MyApp(this.db, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Category Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CategoryTracker(db, title: 'Item Counter'),
    );
  }
}

class CategoryTracker extends StatefulWidget {
  final String title;
  final TextEditingController categoryNameController = TextEditingController();
  final Persistence db;

  CategoryTracker(
    this.db, {
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<CategoryTracker> createState() => _CategoryTrackerState();
}

class _CategoryTrackerState extends State<CategoryTracker> {
  List<Category> categories = [];
  int selectedCategory = 0;
  bool categoriesInitialized = false;

  _CategoryTrackerState();

  Future<void> _initializeCategories() async {
    categories = await widget.db.readCategories();
    setState(() {
      categoriesInitialized = true;
    });
  }

  void _addCategory() {
    setState(() async {
      categories.add(Category(widget.categoryNameController.text, []));
      categories.sort();
    });
  }

  void _editSelectedCategory() {
    setState(() {
      widget.db.updateCategory(
        categories[selectedCategory].name ?? '',
        widget.categoryNameController.text,
      );
      categories[selectedCategory].name = widget.categoryNameController.text;
    });
  }

  void _resetAllCategories() {
    setState(() {
      for (var category in categories) {
        for (var subCategory in category.subCategories ?? <SubCategory>[]) {
          subCategory.reset();
          widget.db.updateSubCategory(
            0,
            subCategory.name ?? '',
            category.name ?? '',
          );
        }
      }
    });
  }

  void _removeSelectedCategory() {
    setState(() {
      widget.db.deleteCategory(categories[selectedCategory].name ?? '');
      categories.removeAt(selectedCategory);
      if (selectedCategory >= categories.length) {
        if (categories.isEmpty) {
          selectedCategory = 0;
        } else {
          selectedCategory = categories.length - 1;
        }
      }
    });
  }

  void _updateSubCategoryCount(SubCategory category) {
    setState(() {
      widget.db.updateSubCategory(
        category.count,
        category.name ?? '',
        categories[selectedCategory].name ?? '',
      );
    });
  }

  void _deleteSubCategory(Category parent, SubCategory sub) {
    setState(() {
      parent.deleteSubCategory(sub);
      widget.db.deleteSubCategory(
        sub.name ?? '',
        categories[selectedCategory].name ?? '',
      );
    });
  }

  void _addSubCategory() {
    setState(() {
      categories[selectedCategory]
          .addSubCategory(widget.categoryNameController.text);
    });
  }

  void _changeSelectedTab(int index) {
    setState(() {
      selectedCategory = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!categoriesInitialized) {
      _initializeCategories();
      return const Center(child: CircularProgressIndicator());
    } else {
      return DefaultTabController(
        length: categories.length,
        initialIndex: selectedCategory,
        child: Scaffold(
          endDrawer: makeDrawerMenu(),
          appBar: AppBar(
            bottom: TabBar(
              onTap: _changeSelectedTab,
              isScrollable: true,
              tabs: createCategoryTabs(),
            ),
            title: Text(widget.title),
          ),
          body: ListView(children: createSubCategories()),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (categories.isEmpty) {
                return;
              }
              showCategoryTabsDialog(() async {
                try {
                  await widget.db.createSubCategory(
                    categories[selectedCategory].name ?? '',
                    widget.categoryNameController.text,
                  );
                  _addSubCategory();
                } catch (e) {
                  showErrorDialog('Sub-Category Already Exists');
                }
              });
            },
            tooltip: 'Add Sub Category',
            child: const Icon(Icons.add),
          ),
        ),
      );
    }
  }

  Widget makeDrawerMenu() {
    return Drawer(
      child: ListView(
        children: [
          InkWell(
            onTap: () async {
              Navigator.pop(context);
              showCategoryTabsDialog(() async {
                try {
                  await widget.db.createCategory(
                    widget.categoryNameController.text,
                  );
                  _addCategory();
                } catch (e) {
                  showErrorDialog('Category Already Exists');
                }
              });
            },
            child: Row(
              children: const [
                SizedBox(width: 10),
                Icon(Icons.add_circle),
                SizedBox(
                  width: 10,
                  height: 60,
                ),
                Text('Add Category'),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              if (categories.isEmpty) {
                return;
              }
              showConfirmDialog(
                _removeSelectedCategory,
                'Remove Full Category?',
              );
            },
            child: Row(
              children: const [
                SizedBox(width: 10),
                Icon(Icons.remove_circle),
                SizedBox(
                  width: 10,
                  height: 60,
                ),
                Text('Delete Category'),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              if (categories.isEmpty) {
                return;
              }
              showCategoryTabsDialog(
                _editSelectedCategory,
                editText: categories[selectedCategory].name,
              );
            },
            child: Row(
              children: const [
                SizedBox(width: 10),
                Icon(Icons.edit),
                SizedBox(
                  width: 10,
                  height: 60,
                ),
                Text('Edit Category'),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              showConfirmDialog(
                _resetAllCategories,
                'Reset all sub-categories to zero?',
              );
            },
            child: Row(
              children: const [
                SizedBox(width: 10),
                Icon(Icons.restore),
                SizedBox(
                  width: 10,
                  height: 60,
                ),
                Text('Reset Sub-Categories'),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return ConsolidatedView(
                      categories: categories,
                    );
                  },
                ),
              );
            },
            child: Row(
              children: const [
                SizedBox(width: 10),
                Icon(Icons.view_list),
                SizedBox(
                  width: 10,
                  height: 60,
                ),
                Text('Consolidated List'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> createCategoryTabs() {
    var tabs = <Widget>[];
    for (var category in categories) {
      tabs.add(
        Tab(
          child: Text(
            category.name ?? "",
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return tabs;
  }

  void showCategoryTabsDialog(Function onOkay, {editText = ""}) {
    widget.categoryNameController.text = editText;

    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Category Editor'),
        content: TextField(
          controller: widget.categoryNameController,
          decoration: getTextFieldBorderDecoration('Category Name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            onPressed: () {
              Navigator.pop(context, 'OK');
              onOkay();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showConfirmDialog(Function onOkay, String title) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            onPressed: () {
              Navigator.pop(context, 'OK');
              onOkay();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showErrorDialog(String title) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            onPressed: () {
              Navigator.pop(context, 'OK');
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> createSubCategories() {
    if (categories.isEmpty) {
      return [];
    }
    var widgets = <Widget>[];
    var category = categories[selectedCategory];
    for (var subCategory in category.subCategories ?? <SubCategory>[]) {
      widgets.add(
        SizedBox(
          height: 60,
          child: Card(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _deleteSubCategory(category, subCategory),
                  icon: const Icon(Icons.delete),
                ),
                Text(
                  '${subCategory.name}: ${subCategory.count}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    subCategory.reset();
                    _updateSubCategoryCount(subCategory);
                  },
                  icon: const Icon(Icons.restore),
                ),
                IconButton(
                  onPressed: () {
                    subCategory.decrement();
                    _updateSubCategoryCount(subCategory);
                  },
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: () {
                    subCategory.increment();
                    _updateSubCategoryCount(subCategory);
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      );
    }

    widgets.add(const SizedBox(height: 110));

    return widgets;
  }

  InputDecoration getTextFieldBorderDecoration(String hintText,
      {String? errorText}) {
    return InputDecoration(
      hintText: hintText,
      enabledBorder: const OutlineInputBorder(),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      errorText: errorText,
    );
  }
}
