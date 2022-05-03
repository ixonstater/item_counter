class Category implements Comparable {
  String? name;
  List<SubCategory>? subCategories;
  Category(this.name, this.subCategories);

  addSubCategory(String name) {
    subCategories?.add(SubCategory(name));
    sortSubCategories();
  }

  deleteSubCategory(SubCategory obj) {
    subCategories?.removeWhere((element) => element.name == obj.name);
    sortSubCategories();
  }

  sortSubCategories() {
    subCategories?.sort();
  }

  @override
  int compareTo(other) {
    return name?.compareTo(other.name ?? '') ?? 0;
  }
}

class SubCategory implements Comparable {
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

  @override
  int compareTo(other) {
    return name?.compareTo(other.name ?? '') ?? 0;
  }
}
