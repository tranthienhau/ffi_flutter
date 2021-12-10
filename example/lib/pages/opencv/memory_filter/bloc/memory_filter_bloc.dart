import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:ffi_flutter/native_ffi.dart';
import 'package:ffi_flutter_example/services/image/image_transfer_service.dart';
import 'package:ffi_flutter_example/services/image/tensorflow_transfer_service.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

part 'memory_filter_event.dart';

part 'memory_filter_state.dart';

class MemoryFilterBloc extends Bloc<MemoryFilterEvent, MemoryFilterState> {
  MemoryFilterBloc({ImageTransferService? imageTransferService})
      : super(MemoryFilterLoading()) {
    _imageTransferService = imageTransferService ?? TensorflowTransferService();
    on<MemoryFilterLoaded>(_onLoaded);
    on<MemoryFilterThumbnailLoaded>(_onThumbnailLoaded);
    on<MemoryFilterColorFiltered>(_onColorTransfered);
    on<MemoryFilterCategoryChanged>(_onCategoryChanged);
    on<MemoryFilterTransferFiltered>(_onTransferFiltered);
    on<MemoryFilterTransferFilterCompleted>(_onFilterCompleted);
    on<MemoryFilterImageSaved>(_onImageSaved);
  }

  final NativeImageFilter _thumbnaiProcessFilter = NativeImageFilter();

  final NativeImageFilter _originProcesssFilter = NativeImageFilter();
  final logger = Logger();
  late final ImageTransferService _imageTransferService;

  CancelableOperation? cancellableOperation;

  final processTensorflowLock = Lock();
  final lock = Lock();

  Future<void> _onImageSaved(
      MemoryFilterImageSaved event, Emitter<MemoryFilterState> emit) async {
    final data = state.data;
    if (data != null) {
      try {
        emit(MemoryFilterBusy(data));
        final transferImage = data.transferImage;
        if (transferImage != null) {
          final now = DateTime.now();

          await ImageGallerySaver.saveImage(
            transferImage,
            quality: 100,
            name: "filter_${now.millisecondsSinceEpoch}",
          );

          emit(MemoryFilterImageSaveSuccess(data));
          return;
        }
        throw Exception('Please choose filter first!');
      } catch (e, _) {
        emit(MemoryFilterImageSaveFailure(data, e.toString()));
      }
    }
  }

  Future<void> _onFilterCompleted(MemoryFilterTransferFilterCompleted event,
      Emitter<MemoryFilterState> emit) async {
    final data = state.data;
    if (data != null) {
      emit(
        MemoryFilterLoadSuccess(
          data.copyWith(
              transferFilterData: data.transferFilterData.copyWith(
                selectedIndex: event.selectedIndex,
                // transferFilterList: transferList,
              ),
              transferImage: event.bytes),
        ),
      );
    }
  }

  Future<void> _onTransferFiltered(MemoryFilterTransferFiltered event,
      Emitter<MemoryFilterState> emit) async {
    final data = state.data;
    if (data != null) {
      final transferList = data.transferFilterData.transferFilterList;
      final selectedIndex = transferList
          .indexWhere((element) => element.thumbnailPath == event.stylePath);

      await processTensorflowLock.synchronized(
        () async {
          emit(MemoryFilterTransferFilterBusy(data));

          Uint8List originImage = data.originImage;

          try {
            final styleImageByteData = await rootBundle.load(event.stylePath);
            final styleBytes = styleImageByteData.buffer.asUint8List();

            await _imageTransferService.selectStyle(styleBytes);

            final transferImage =
                await _imageTransferService.transfer(originImage, 0.4);
            transferList[selectedIndex] =
                transferList[selectedIndex].copyWith();

            emit(
              MemoryFilterLoadSuccess(
                data.copyWith(
                  transferFilterData: data.transferFilterData.copyWith(
                    selectedIndex: selectedIndex,
                    // transferFilterList: transferList,
                  ),
                  transferImage: transferImage ?? data.originImage,
                ),
              ),
            );
          } catch (e, stack) {
            logger.e('TransferFilterStyleLoadFailure', e.toString(), stack);
          }
        },
      );
    }
  }

  Future<void> _onCategoryChanged(MemoryFilterCategoryChanged event,
      Emitter<MemoryFilterState> emit) async {
    final data = state.data;
    if (data != null) {
      // await _transferConpleter?.future;

      emit(
        MemoryFilterLoadSuccess(
          data.copyWith(
            category: event.category,
            colorFilterData: data.colorFilterData.copyWith(selectedIndex: -1),
            transferFilterData:
                data.transferFilterData.copyWith(selectedIndex: -1),
            transferImage: data.originImage,
          ),
        ),
      );
    }
  }

  Future<void> _onThumbnailLoaded(MemoryFilterThumbnailLoaded event,
      Emitter<MemoryFilterState> emit) async {
    final data = state.data;
    if (data != null) {
      final colorFilterData = data.colorFilterData;
      final colorFilterList =
          List<ColorFilter>.from(colorFilterData.colorFilterList);

      int findIndex = colorFilterList
          .indexWhere((element) => element.filter == event.data.filter);

      if (findIndex != -1) {
        colorFilterList[findIndex] = colorFilterList[findIndex].copyWith(
          thumbnailFilter: event.data.bytes,
        );

        emit(
          MemoryFilterLoadSuccess(
            data.copyWith(
              colorFilterData: colorFilterData.copyWith(
                colorFilterList: colorFilterList,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _onColorTransfered(
      MemoryFilterColorFiltered event, Emitter<MemoryFilterState> emit) async {
    final data = state.data;
    if (data != null) {
      final colorFilterData = data.colorFilterData;
      final colorFilterList =
          List<ColorFilter>.from(colorFilterData.colorFilterList);

      int findIndex = colorFilterList
          .indexWhere((element) => element.filter == event.filter);

      if (findIndex != -1) {
        final originFilter = colorFilterList[findIndex].originFilter;
        if (originFilter != null) {
          emit(
            MemoryFilterLoadSuccess(
              data.copyWith(
                colorFilterData: colorFilterData.copyWith(
                  colorFilterList: colorFilterList,
                  selectedIndex: findIndex,
                ),
                transferImage: originFilter,
              ),
            ),
          );
          return;
        }

        final bytes = await _originProcesssFilter.processImageFilter(
            filter: event.filter);

        if (bytes != null) {
          colorFilterList[findIndex] =
              colorFilterList[findIndex].copyWith(originFilter: bytes);

          emit(
            MemoryFilterLoadSuccess(
              data.copyWith(
                colorFilterData: colorFilterData.copyWith(
                  colorFilterList: colorFilterList,
                  selectedIndex: findIndex,
                ),
                transferImage: bytes,
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _onLoaded(
      MemoryFilterLoaded event, Emitter<MemoryFilterState> emit) async {
    final originBytes =
        await _originProcesssFilter.loadOriginImagePath(event.imagePath);

    await _thumbnaiProcessFilter.loadOriginBytes(event.thumnail);

    await _imageTransferService.init();

    await _imageTransferService.loadImage(originBytes);
    final templateColorFilters = ImageFilter.values
        .map((filter) => ColorFilter(
              filter: filter,
            ))
        .toList();
    templateColorFilters
        .removeWhere((element) => element.filter == ImageFilter.original);
    templateColorFilters.insert(
        0,
        ColorFilter(
          filter: ImageFilter.original,
          thumbnailFilter: originBytes,
          originFilter: originBytes,
        ));

    final transferFilters = await _createTransferFilterThumbnails();

    emit(
      MemoryFilterLoadSuccess(
        MemoryFilterData(
          originImage: originBytes,
          transferFilterData: TransferFilterListData(
            transferFilterList: transferFilters,
            selectedIndex: -1,
          ),
          colorFilterData: ColorFilterListData(
            colorFilterList: templateColorFilters,
            selectedIndex: -1,
          ),
          categories: [
            'Color',
            'Cartoon',
          ],
          category: 'Color',
        ),
      ),
    );

    final Stream<NativeImageFilterData?> streamThumnailFilter =
        await _thumbnaiProcessFilter.processAllFiltersStream();

    streamThumnailFilter.listen(
      (filterData) {
        if (filterData != null) {
          add(
            MemoryFilterThumbnailLoaded(filterData),
          );
        }
      },
    );


  }

  Future<List<TransferFilter>> _createTransferFilterThumbnails() async {
    final transferFilters = List.generate(
      28,
      (index) {
        String path = 'assets/images/style$index.jpg';
        if (index >= 26) {
          path = 'assets/images/style$index.jpeg';
        }
        return TransferFilter(thumbnailPath: path);
      },
    );

    return transferFilters;
  }

  Future<List<ColorFilter>> _createColorFilterThumbnails(
      Uint8List originBytes) async {
    final s1List = List.generate(3, (index) => index);
    final s2List = List.generate(4, (index) => index);
    final s3List = List.generate(2, (index) => index);
    final exponentList = List.generate(10, (index) => index);

    final List<ColorFilter> colorFilters = [];
    colorFilters.add(ColorFilter(
      thumbnailFilter: originBytes,
      originFilter: originBytes,
      filter: ImageFilter.original,
    ));

    for (int exponent in exponentList) {
      for (int s1 in s1List) {
        for (int s2 in s2List) {
          for (int s3 in s3List) {
            final filterBytes =
                await _originProcesssFilter.processDuoToneFilter(
              exponent: exponent.toDouble(),
              s1: s1,
              s2: s2,
              s3: s3,
            );

            if (filterBytes != null) {
              colorFilters.add(
                ColorFilter(
                  thumbnailFilter: filterBytes,
                  filter: ImageFilter.original,
                ),
              );
            }
          }
        }
      }
    }

    return colorFilters;
  }

  @override
  Future<void> close() {
    _thumbnaiProcessFilter.dispose();
    _originProcesssFilter.dispose();
    return super.close();
  }
}
