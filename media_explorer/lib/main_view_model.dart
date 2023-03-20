import 'dart:io';

import 'package:file/local.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_explorer/main.dart';

final mainViewModelNotifierProvider =
    ChangeNotifierProvider((ref) => MainViewModel());

extension FileSystemEntityExtension on FileSystemEntity {
  // xxx.jpg
  String get nameWithType {
    return path.split('/').last;
  }

  // xxx
  String get name {
    return nameWithType.split('.').first;
  }

  //
  ItemType get type {
    return path.itemType;
  }
}

class ItemModel {
  final FileSystemEntity? image;
  final FileSystemEntity? movie;

  ItemModel({this.image, this.movie});
}

enum PageState {
  normal,
  loading,
  error,
}

class MainViewModel extends ChangeNotifier {
  PageState _pageState = PageState.normal;
  PageState get pageState => _pageState;
  set pageState(PageState value) {
    _pageState = value;
    notifyListeners();
  }

  // 全て項目
  List<FileSystemEntity> totalItemList = [];
  // 画像
  List<ItemModel> totalImageItemList = [];
  // 動画ある画像
  List<ItemModel> totalHadMovieImageItemList = [];
  // 動画なし画像
  List<ItemModel> totalHasNotMovieImageItemList = [];
  // 画像なし動画
  List<ItemModel> totalHasNotImageMovieItemList = [];
  // 動画
  List<ItemModel> totalMovieList = [];
  // compute処理用total item list
  static final totalItemListCompute = <FileSystemEntity>[];
  final LocalFileSystem fs = const LocalFileSystem();

  final pageList = <Widget>[];
  final bottomNavigationBarList = <BottomNavigationBarItem>[];

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
    pageController.jumpToPage(index);
  }

  late final PageController pageController;

  MainViewModel() {
    // _load();
    pageController = PageController(initialPage: currentIndex);
  }

  void loadData() async {
    pageState = PageState.loading;

    totalItemList.clear();
    totalImageItemList.clear();
    totalMovieList.clear();
    totalHadMovieImageItemList.clear();
    totalHasNotMovieImageItemList.clear();
    totalHasNotImageMovieItemList.clear();
    pageList.clear();
    bottomNavigationBarList.clear();

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final result = await compute(getAllFileSystemEntity, selectedDirectory);
      totalItemList = result;
      totalImageItemList = await compute(getAllImageItem, totalItemList);
      totalMovieList = await compute(getAllMovieItem, totalItemList);
      totalHadMovieImageItemList =
          await compute(getHadMovieImageItemList, totalItemList);
      totalHasNotMovieImageItemList =
          await compute(getHasNotMovieImageItemList, totalItemList);
      totalHasNotImageMovieItemList =
          await compute(getHasNotImageMovieItemList, totalItemList);
      pageList.add(TotalImagePage(list: totalHadMovieImageItemList));
      bottomNavigationBarList.add(
        const BottomNavigationBarItem(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.add),
          label: '動画あり画像一覧',
        ),
      );
      pageList.add(TotalImagePage(list: totalHasNotMovieImageItemList));
      bottomNavigationBarList.add(
        const BottomNavigationBarItem(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.add),
          label: '動画なし画像一覧',
        ),
      );
      pageList.add(TotalImagePage(list: totalHasNotImageMovieItemList));
      bottomNavigationBarList.add(
        const BottomNavigationBarItem(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.add),
          label: '画像なし動画一覧',
        ),
      );
      pageList.add(TotalImagePage(list: totalMovieList));
      bottomNavigationBarList.add(
        const BottomNavigationBarItem(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.add),
          label: '動画一覧',
        ),
      );
      pageList.add(TotalImagePage(list: totalImageItemList));
      bottomNavigationBarList.add(
        const BottomNavigationBarItem(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.add),
          label: '画像一覧',
        ),
      );

      pageState = PageState.normal;
    }
  }

  static List<FileSystemEntity> getAllFileSystemEntity(String path) {
    getAllSubFile(path);
    return MainViewModel.totalItemListCompute;
  }

  ///遍历所有文件
  static getAllSubFile(String path) {
    Directory directory = Directory(path);
    if (directory.existsSync()) {
      final list = directory.listSync();
      for (var item in list) {
        final path = item.path;
        final tempList = path.split('/');
        if (tempList.length > 1) {
          if (tempList.last.startsWith('.')) {
            // 権限がない
          } else {
            // 普通の
            getAllSubFile(path);
            MainViewModel.totalItemListCompute.add(item);
          }
        }
      }
    }
  }

  static List<ItemModel> getAllImageItem(
    List<FileSystemEntity> list,
  ) {
    final result = <ItemModel>[];
    for (var e in list) {
      if (e.type == ItemType.image) {
        result.add(ItemModel(image: e));
      }
    }
    return result;
  }

  static List<ItemModel> getAllMovieItem(
    List<FileSystemEntity> list,
  ) {
    final result = <ItemModel>[];
    for (var e in list) {
      if (e.type == ItemType.movie) {
        result.add(ItemModel(image: e));
      }
    }
    return result;
  }

  static List<ItemModel> getHadMovieImageItemList(
    List<FileSystemEntity> list,
  ) {
    final movieNameList = <String>[];
    final movieList = <FileSystemEntity>[];
    for (var e in list) {
      if (e.type == ItemType.movie) {
        movieNameList.add(e.name);
        movieList.add(e);
      }
    }
    final result = <ItemModel>[];
    for (var e in list) {
      if (e.type == ItemType.image && movieNameList.contains(e.name)) {
        final index = movieNameList.indexOf(e.name);
        result.add(ItemModel(image: e, movie: movieList[index]));
      }
    }
    return result;
  }

  static List<ItemModel> getHasNotMovieImageItemList(
    List<FileSystemEntity> list,
  ) {
    final movieNameList = <String>[];
    final tempList = <String>[];
    for (var e in list) {
      if (e.type == ItemType.movie) {
        tempList.add(e.name);
      }
    }
    movieNameList.addAll(tempList.where((element) => element.isNotEmpty));

    final result = <ItemModel>[];
    for (var e in list) {
      if (e.type == ItemType.image && !movieNameList.contains(e.name)) {
        result.add(ItemModel(image: e));
      }
    }
    return result;
  }

  static List<ItemModel> getHasNotImageMovieItemList(
    List<FileSystemEntity> list,
  ) {
    final imageNameList = <String>[];
    final tempList = <String>[];
    for (var e in list) {
      if (e.type == ItemType.image) {
        tempList.add(e.name);
      }
    }
    imageNameList.addAll(tempList.where((element) => element.isNotEmpty));

    final result = <ItemModel>[];
    for (var e in list) {
      if (e.type == ItemType.movie && !imageNameList.contains(e.name)) {
        result.add(ItemModel(image: e));
      }
    }
    return result;
  }
}
