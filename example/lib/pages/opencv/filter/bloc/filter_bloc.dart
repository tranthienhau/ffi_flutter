import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:native_ffi/native_ffi.dart';
import 'package:path_provider/path_provider.dart';

part 'filter_event.dart';

part 'filter_state.dart';

class FilterBloc extends Bloc<FilterEvent, FilterState> {
  FilterBloc()
      : super(const FilterLoading(
          FilterBlocData(
             selectionIndex: -1, imageFilterDataMap: {}),
        )) {
    on<FilterLoaded>(_onLoaded);
    on<FilterUpload>(_onUpload);
    on<FilterImageSelected>(_onImageSelected);
    // on<FilterUpdated>(_onUpdated);
    on<FilterThumnailUpdated>(_onThumnailUpdated);
    on<FilterOriginalUpdated>(_onOriginalUpdated);
  }

  final logger = Logger();
  final NativeCurl _nativeCurl = NativeCurl();
  final NativeCv _nativeCv = NativeCv();

  Completer<void>? _updateCompleter;

  Future<void> _onOriginalUpdated(
      FilterOriginalUpdated event, Emitter<FilterState> emit) async {
    final original = event.original;
    final filter = event.filter;
    final imageFilterDataMap = state.data.imageFilterDataMap;

    final filterData = imageFilterDataMap[filter];
    if (filterData != null) {
      imageFilterDataMap[filter] = filterData.copyWith(
        original: original,
      );
    } else {
      imageFilterDataMap[filter] = FilterData(
        original: original,
        thumnail: original,
      );
    }

    emit(
      FilterLoadSuccess(
        state.data.copyWith(
          imageFilterDataMap: imageFilterDataMap,
        ),
      ),
    );
  }

  Future<void> _onThumnailUpdated(
      FilterThumnailUpdated event, Emitter<FilterState> emit) async {
    final thumnail = event.thumnail;
    final filter = event.filter;
    final imageFilterDataMap = state.data.imageFilterDataMap;

    final filterData = imageFilterDataMap[filter];
    if (filterData != null) {
      imageFilterDataMap[filter] = filterData.copyWith(
        thumnail: thumnail,
      );
    } else {
      imageFilterDataMap[filter] = FilterData(
        thumnail: thumnail,
      );
    }

    emit(
      FilterLoadSuccess(
        state.data.copyWith(
          imageFilterDataMap: imageFilterDataMap,
        ),
      ),
    );
  }

  // Future<void> _onUpdated(
  //     FilterUpdated event, Emitter<FilterState> emit) async {
  //   final filterMap = state.data.imageFilterDataMap;
  //
  //   final ImageFilterData filterData = event.filterData;
  //   filterMap[filterData.filter] = filterData.filterPath;
  //
  //   emit(
  //     FilterLoadSuccess(
  //       state.data.copyWith(
  //         imageFilterDataMap: imageFilterDataMap,
  //       ),
  //     ),
  //   );
  //
  //   // _updateCompleter?.complete();
  // }

  Future<void> _onImageSelected(
      FilterImageSelected event, Emitter<FilterState> emit) async {
    emit(
      FilterSelectionChange(
        state.data.copyWith(
          selectionIndex: event.index,
        ),
      ),
    );
  }

  StreamSubscription? _streamSubscription;

  Future<void> _onLoaded(FilterLoaded event, Emitter<FilterState> emit) async {
    await _initCurl();

    final imageFilterDataMap = <ImageFilter, FilterData?>{};
    for (final filter in ImageFilter.values) {
      imageFilterDataMap[filter] = null;
    }

    emit(
      FilterLoadSuccess(
        state.data.copyWith(
          imageFilterDataMap: imageFilterDataMap,
          selectionIndex: 0,
        ),
      ),
    );

    try {
      final fileNameEx = event.imagePath.split('/').last;
      final fileName = fileNameEx.split('.').first;
      final extension = fileNameEx.split('.').last;

      final path = await _localPath;
      final thumnailPath = '$path/${fileName}_thumnail.$extension';

      await File(thumnailPath).writeAsBytes(event.thumnail);

      final Stream<ImageFilterData?> streamThumnailFilter =
          await _nativeCv.processAllFiltersStream(thumnailPath);

      streamThumnailFilter.listen(
        (filterData) {
          if (filterData != null) {
            add(
              FilterThumnailUpdated(
                thumnail: filterData.filterPath,
                filter: filterData.filter,
              ),
            );
          }
        },
      );

      final Stream<ImageFilterData?> streamOriginFilter =
          await _nativeCv.processAllFiltersStream(event.imagePath);
      streamOriginFilter.listen(
        (filterData) {
          if (filterData != null) {
            add(
              FilterOriginalUpdated(
                original: filterData.filterPath,
                filter: filterData.filter,
              ),
            );
          }
        },
      );
    } catch (e, stack) {
      logger.e('Apply filter error', e.toString(), stack);
    }
  }

  Future<void> _onUpload(FilterUpload event, Emitter<FilterState> emit) async {
    if (state.data.selectionIndex == -1) {
      return;
    }

    emit(FilterBusy(state.data));

    final filter =
        state.data.imageFilterDataMap.keys.elementAt(state.data.selectionIndex);

    try {
      final reponseData = await _nativeCurl.postFormData(
        url: 'https://api.kraken.io/v1/upload',
        formDataList: [
          FormData(
            type: FormDataType.file,
            name: 'upload',
            value: state.data.imageFilterDataMap[filter]!.original!,
          ),
          FormData(
            type: FormDataType.text,
            value:
                "{\"auth\":{\"api_key\": \"42e4ab284ddbc382444d292743c2c861\", "
                "\"api_secret\": \"c2ccdf0f9803f25e26f0f98b3de208220d862237\"}, "
                "\"wait\":true"
                "}",
            name: 'data',
          ),
        ],
      );

      final data = reponseData?.data;
      if (data != null) {
        final map = json.decode(data);
        logger.i(map);

        emit(FilterUploadSuccess(state.data));
      }
    } catch (e, stack) {
      logger.e('Upload image error', e.toString(), stack);
      emit(FilterUploadFailure(error: e.toString(), data: state.data));
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<void> _initCurl() async {
    final path = await _localPath;
    ByteData data = await rootBundle.load('assets/cacert.pem');
    final cacertFile = File('$path/cacert.pem');
    final buffer = data.buffer;

    await cacertFile.writeAsBytes(
      buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      ),
    );
    _nativeCurl.init(cacertFile.path);
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
