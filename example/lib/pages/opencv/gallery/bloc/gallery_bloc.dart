import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:ffi_flutter_example/pages/opencv/gallery/model/gallery_asset.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

part 'gallery_event.dart';

part 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  GalleryBloc()
      : super(
          GalleryLoading(
            GalleryBlocData(currentPage: 0, mapGalleryCategory: {}),
          ),
        ) {
    on<GalleryLoaded>(_onLoaded);
    on<GalleryAssetLoaded>(_onAssetLoaded);
    on<GalleryPageChanged>(_onPageChanged);
    on<GalleryGalleryLoadMore>(_onPageLoadMore);
  }

  final _logger = Logger();

  final Map<String, List<AssetEntity>> _mapAssetEntities = {};
  final List<AssetPathEntity> _assetPathEntities = [];

  final int _pageSize = 20;

  ///Load gallery catergories from phone
  Future<void> _onLoaded(
      GalleryLoaded event, Emitter<GalleryState> emit) async {
    try {
      List<AssetPathEntity> assetPathEntities =
          await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(),
      );

      final Map<String, List<GalleryAsset>?> mapGalleryCategory = {};

      if (assetPathEntities.isNotEmpty) {
        for (final AssetPathEntity assetPath in assetPathEntities) {
          if (assetPath.assetCount != 0) {
            _assetPathEntities.add(assetPath);
            mapGalleryCategory[assetPath.name] = null;
            _mapAssetEntities[assetPath.name] = [];
          }
        }
        emit(
          GalleryLoading(
            GalleryBlocData(
              currentPage: 0,
              mapGalleryCategory: mapGalleryCategory,
            ),
          ),
        );
        if (_assetPathEntities.isNotEmpty) {
          await _onPageLoaded(emit: emit, page: 0);
        }
      }
    } catch (e, stack) {
      _logger.e('GalleryLoadFailure', e.toString(), stack);

      emit(GalleryLoadFailure(error: e.toString(), data: state.data));
    }
  }

  Future<void> _onPageChanged(
      GalleryPageChanged event, Emitter<GalleryState> emit) async {
    final mapGalleryCategory = state.data.mapGalleryCategory;
    final AssetPathEntity assetPathEntity = _assetPathEntities[event.page];

    emit(
      GalleryLoadSuccess(
        state.data.copyWith(
          currentPage: event.page,
        ),
      ),
    );

    if (mapGalleryCategory[assetPathEntity.name] == null) {
      await _onPageLoaded(emit: emit, page: event.page);
    }
  }

  Future<void> _onPageLoadMore(
      GalleryGalleryLoadMore event, Emitter<GalleryState> emit) async {
    final AssetPathEntity assetPathEntity = _assetPathEntities[event.page];

    final List<AssetEntity> assets =
        _mapAssetEntities[assetPathEntity.name] ?? [];

    if (assets.length < assetPathEntity.assetCount) {
      final int start = assets.length;
      final int end = assets.length + _pageSize;
      await _onPageLoaded(
        emit: emit,
        page: event.page,
        start: start,
        end: end,
      );
    }
  }

  Future<void> _onPageLoaded({
    required Emitter<GalleryState> emit,
    required int page,
    int? start,
    int? end,
  }) async {
    final AssetPathEntity assetPathEntity = _assetPathEntities[page];

    final mapGalleryCategory = state.data.mapGalleryCategory;

    List<AssetEntity> assetEntities = await assetPathEntity.getAssetListRange(
      start: start ?? 0,
      end: end ?? _pageSize,
    );
    _mapAssetEntities[assetPathEntity.name] = assetEntities;

    final List<GalleryAsset> assets = [];

    for (final AssetEntity assetEntity in assetEntities) {
      final bytes = await assetEntity.thumbData;
      String? title = assetEntity.title;
      title ??= await assetEntity.titleAsync;

      String id = assetEntity.id;
      if (bytes != null) {
        assets.add(GalleryAsset(title: title, id: id, bytes: bytes));
      }
    }

    if (mapGalleryCategory[assetPathEntity.name] == null) {
      mapGalleryCategory[assetPathEntity.name] = [];
    }

    mapGalleryCategory[assetPathEntity.name]?.addAll(assets);

    ///return data to UI each time add a new [GalleryCategory]
    emit(
      GalleryLoadSuccess(
        state.data.copyWith(
          mapGalleryCategory: mapGalleryCategory,
        ),
      ),
    );
  }

  ///Get file of [GalleryAsset]
  Future<void> _onAssetLoaded(
      GalleryAssetLoaded event, Emitter<GalleryState> emit) async {
    final List<AssetEntity> assets = _mapAssetEntities[event.galleryName] ?? [];

    final assetIndex = state.data.mapGalleryCategory[event.galleryName]!
        .indexWhere((element) => element == event.asset);

    final file = await assets[assetIndex].originFile;

    if (file != null) {
      String fileFullName = file.path.split('/').last;
      String fileExtension = fileFullName.split('.').last;
      String fileName = fileFullName.split('.').first;

      final resizeBytes = await assets[assetIndex].thumbDataWithSize(800, 800);
      final thumnailBytes = await assets[assetIndex].thumbDataWithSize(100, 100);

      if (resizeBytes != null && thumnailBytes != null) {
        final localPath = await _localPath;
        final resizePath = '$localPath/${fileName}_resize.$fileExtension';

        final rezeFile = await File(resizePath).writeAsBytes(resizeBytes);

        emit(GalleryAssetLoadSuccess(
          file: rezeFile,
          data: state.data,
          thumnail: thumnailBytes,
        ));
        return;
      }

      emit(GalleryAssetLoadSuccess(
        file: file,
        data: state.data,
        thumnail: event.asset.bytes,
      ));
      return;
    }

    emit(GalleryAssetLoadFailure(
      error: 'Can not access to this asset',
      data: state.data,
    ));
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  @override
  Future<void> close() {
    PhotoCachingManager().cancelCacheRequest();
    return super.close();
  }
}
