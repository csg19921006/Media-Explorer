import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:media_explorer/main_view_model.dart';
import 'package:open_app_file/open_app_file.dart';

void main() {
  runApp(const ProviderScope(child: MainPage()));
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Consumer(builder: (context, ref, _) {
          final pageState = ref.watch(mainViewModelNotifierProvider).pageState;
          final viewModel = ref.watch(mainViewModelNotifierProvider);
          final totalImageItemList =
              ref.watch(mainViewModelNotifierProvider).totalImageItemList;
          final pageList = ref.watch(mainViewModelNotifierProvider).pageList;
          final controller =
              ref.watch(mainViewModelNotifierProvider).pageController;
          final currentIndex =
              ref.watch(mainViewModelNotifierProvider).currentIndex;
          final bottomNavigationBarList =
              ref.watch(mainViewModelNotifierProvider).bottomNavigationBarList;
          final Widget body;
          final Widget? bottomNavigationBar;
          switch (pageState) {
            case PageState.normal:
              if (pageList.isEmpty) {
                body = Column(
                  children: [
                    Text('tttt'),
                  ],
                );
                bottomNavigationBar = null;
              } else {
                body = PageView(
                  controller: controller,
                  children: pageList,
                );
                bottomNavigationBar = BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    ref.read(mainViewModelNotifierProvider).currentIndex =
                        index;
                  },
                  items: bottomNavigationBarList,
                );
              }
              break;
            case PageState.loading:
              body = const Center(child: CircularProgressIndicator());
              bottomNavigationBar = null;
              break;
            case PageState.error:
              body = Container();
              bottomNavigationBar = null;
              break;
          }
          return Scaffold(
            appBar: AppBar(),
            body: body,
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                viewModel.loadData();
              },
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ), // This trailing comma makes auto-formatting nicer for build methods.
            bottomNavigationBar: bottomNavigationBar,
          );
        }));
  }
}

class ItemWidget extends StatelessWidget {
  final String path;
  const ItemWidget({
    Key? key,
    required this.path,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

enum ItemType {
  image,
  movie,
  other,
}

extension ItemTypeExtension on ItemType {
  Widget widget(String path) {
    switch (this) {
      case ItemType.image:
        return Image.network(
          path,
          width: 100.0,
          height: 100.0,
          fit: BoxFit.contain,
        );
      case ItemType.movie:
        return const Text('movie');
      case ItemType.other:
        return const Text('other');
    }
  }
}

extension StringExtension on String {
  ItemType get itemType {
    if (endsWith('.jpeg') || endsWith('.jpg') || endsWith('.jpeg')) {
      return ItemType.image;
    }
    if (endsWith('.mp4') || endsWith('.wmv') || endsWith('.mkv')) {
      return ItemType.movie;
    }
    return ItemType.other;
  }

  Widget get widget {
    switch (itemType) {
      case ItemType.image:
        const LocalFileSystem fs = LocalFileSystem();
        final file = fs.file(this);
        return Image.file(
          file,
          fit: BoxFit.fitHeight,
        );
      case ItemType.movie:
        return const Text('movie');
      case ItemType.other:
        return const Text('other');
    }
  }
}

class TotalImagePage extends StatelessWidget {
  final List<ItemModel> list;
  const TotalImagePage({Key? key, required this.list}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final children = <Widget>[];
          if (index >= list.length) {
            return Container();
          }
          if (list[index].image != null) {
            children.add(list[index].image!.path.widget);
            children.add(Text(list[index].image!.nameWithType));
            children.add(Text(list[index].image!.path));
          } else if (list[index].movie != null) {
            children.add(Text(list[index].movie!.path));
          }
          return GestureDetector(
            onTap: () {
              try {
                final path = list[index].movie?.path;
                if (path != null) {
                  OpenAppFile.open(path);
                }
              } catch (e) {
                print(e);
              }
            },
            child: Column(children: children),
          );
        });
  }
}

class TotalMoviePage extends StatelessWidget {
  const TotalMoviePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class TotalHasMovieImagePage extends StatelessWidget {
  const TotalHasMovieImagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class TotalHasNotMovieImagePage extends StatelessWidget {
  const TotalHasNotMovieImagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
