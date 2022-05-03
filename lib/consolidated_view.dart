import 'package:flutter/material.dart';
import 'package:item_counter/data_classes.dart';

class ConsolidatedView extends StatelessWidget {
  final List<Category>? categories;
  const ConsolidatedView({Key? key, this.categories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Counter'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: ListView(
          children: [...makeCategories()],
        ),
      ),
    );
  }

  List<Widget> makeCategories() {
    var widgets = <Widget>[];
    if (categories == null) {
      return widgets;
    }
    for (var category in categories!) {
      widgets.add(Text(
        '${category.name}',
        style: const TextStyle(fontSize: 18),
      ));
      widgets.add(const SizedBox(
        height: 3,
      ));
      for (var subCategory in category.subCategories ?? <SubCategory>[]) {
        if (subCategory.count == 0) {
          continue;
        } else {
          widgets.add(Text(
            '${subCategory.name}: ${subCategory.count}',
            style: const TextStyle(fontSize: 15),
          ));
        }
      }
      widgets.add(
        const Divider(
          color: Colors.black,
          endIndent: 20,
          thickness: 1.0,
        ),
      );
    }

    widgets.removeLast();
    return widgets;
  }
}
