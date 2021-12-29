// ignore_for_file: prefer_final_fields, avoid_print

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:tuple/tuple.dart';
import 'package:volo_consumer/services/services.dart';
import 'package:volo_consumer/temp_models.dart';
import 'package:volo_consumer/utils/datamodels/datamodels.dart';
import 'package:volo_consumer/utils/constants/categories.dart';
import 'package:volo_consumer/widgets/stateful_list_tile.dart';

part 'home_state.dart';
part 'home_cubit.freezed.dart';

class HomeCubit extends Cubit<HomeState> {
  final DatabaseService _db = GetIt.instance.get<DatabaseService>();
  final AuthenticationService _auth =
      GetIt.instance.get<AuthenticationService>();
  final NavigationService _nav = GetIt.instance.get<NavigationService>();

  //TODO: change unnecccessary globalkey to local or object key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;
  final GlobalKey<StfulListTileState> logOutListTileKey =
      GlobalKey<StfulListTileState>();

  ScrollController scrollController = ScrollController();

  String get currentUsername =>
      _auth.activeUser != null ? _auth.activeUser!.username : "";
  Enduser get currentUser => _auth.activeUser!;

  DocumentSnapshot? _lastDoc;

  Future<Either<String, Tuple2<List<Post>, DocumentSnapshot>>> _getPosts(
      int? category, DocumentSnapshot? lastdoc) async {
    return await _db.getPostsPaginated(
        category: (category != null) ? category - 1 : null, lastdoc: lastdoc);
  }

  void _initializeCubit() async {
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          state.maybeMap(ready: (_) => true, orElse: () => false)) {
        print("loading more data...........");
      }
    });
    await _getPosts(null, null).fold((left) => print(left), (right) {
      _lastDoc = right.item2;
      emit(HomeState.ready(posts: right.item1, cat: 0));
    });
  }

  HomeCubit() : super(const HomeState.loading()) {
    _initializeCubit();
  }

  @override
  void onChange(Change<HomeState> change) {
    super.onChange(change);
    print(change);

    print(change);
  }

  void requestMorePosts() async {
    List<Post>? result;
    int catt = state.maybeMap(
        ready: (ready) {
          print(ready.cat);
          return ready.cat;
        },
        orElse: () => -1);

    await _getPosts(catt != 0 ? catt : null, _lastDoc).fold((left) {
      print(left);
    }, (right) {
      result = right.item1;
      _lastDoc = right.item2;
    });

    state.maybeMap(
      ready: (Ready readyState) {
        List<Post>? templist = readyState.posts;
        if (result != null) {
          templist.addAll(result!);
        }
        emit(HomeState.ready(posts: templist, cat: catt));
      },
      orElse: () {
        print("here bbbb");
      },
    );
  }

  void changeCategory(int newCat) async {
    if (newCat ==
        state.maybeMap(ready: (ready) => ready.cat, orElse: () => -1)) {
      return;
    }
    emit(const HomeState.loading());
    int? nnewCatt = newCat == 0 ? null : newCat - 1;

    await _getPosts(nnewCatt, null).fold((left) => print(left), (right) {
      _lastDoc = right.item2;
      emit(HomeState.ready(posts: right.item1, cat: newCat));
    });
  }

  void openProfile(String pID) async {
    _nav.pushNamed(routeName: '/profile', arguments: pID);
  }

  //TODO: complete like functinoality
  // toggglelike, has user liked(DataBaseService),
  void toggleLike(String pid, String uid) {}

  BoxDecoration? getBoxDecoration(index) {
    Ready? _readyState;
    state.maybeMap(ready: (Ready val) {
      _readyState = val;
    }, orElse: () {
      return;
    });

    if (_readyState != null) {
      if (_readyState!.cat == index) {
        return const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Colors.pink,
              Colors.purple,
            ],
          ),
        );
      }
    }
  }

  TextStyle getTextStyle(index) {
    Ready? _readyState;
    state.maybeMap(ready: (Ready val) {
      _readyState = val;
    }, orElse: () {
      return;
    });

    if (_readyState != null) {
      if (_readyState!.cat == index) {
        return const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        );
      } else {
        return const TextStyle(
          fontSize: 17,
          color: Colors.black,
        );
      }
    } else {
      return const TextStyle(
        fontSize: 17,
        color: Colors.grey,
      );
    }
  }

  void openDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  void logOut() async {
    logOutListTileKey.currentState!.toggleEnable();
    await _auth.signOut().fold((left) {
      //make a toast instead of navigating
      //_nav.pushreplacementNamed(routeName: '/error');
      logOutListTileKey.currentState!.toggleEnable();
    }, (right) {
      _nav.pushreplacementNamed(routeName: '/login');
    });
  }

  void devFunc() async {
    // final CloudStorageService _storage =
    //     GetIt.instance.get<CloudStorageService>();
    // print("here 1");
    // (await _db.addPost(
    //         profileID: "WNJ9ym91FfwphDEKf6WE",
    //         mUsername: "voloDev",
    //         mPhotoURL:
    //             "https://firebasestorage.googleapis.com/v0/b/volodeals.appspot.com/o/Profiles%2FindUY4ni6KNWwmlKSWROIcaq5j93%2Fdp.jpg?alt=media&token=2ffd5206-4c46-400a-bd23-41f34503144b",
    //         mRating: "0.0",
    //         createDT: DateTime.now(),
    //         pImageURL:
    //             "https://firebasestorage.googleapis.com/v0/b/volodeals.appspot.com/o/Posts%2Fcoffee.jpg?alt=media&token=720eb784-488a-48d7-bc1e-cd221ec74110",
    //         mGeoHash: GeoHash.fromDecimalDegrees(81.0001, 26.8530).geohash,
    //         pCat: 2,
    //         likeCount: 0))
    //     .fold((String s) => print(s), (bool b) => print(b));
    // print("here 2");
    //await requestMorePosts();
  }
}
