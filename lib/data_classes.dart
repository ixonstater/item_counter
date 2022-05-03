class Category {
  String? name;
  List<SubCategory>? subCategories;
  Category(this.name, this.subCategories);

  addSubCategory(String name) {
    subCategories?.add(SubCategory(name));
  }

  deleteSubCategory(SubCategory obj) {
    subCategories?.removeWhere((element) => element.name == obj.name);
  }
}

class SubCategory {
  int count = 0;
  String? name;

  SubCategory(this.name);

  void increment() {
    count++;
  }

  void decrement() {
    if (count > 0) {
      count--;
    }
  }

  void reset() {
    count = 0;
  }
}
