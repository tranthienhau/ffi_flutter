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
            imageFilterMap: {},
            selectionIndex: -1,
          ),
        )) {
    on<FilterLoaded>(_onLoaded);
    on<FilterUpload>(_onUpload);
    on<FilterImageSelected>(_onImageSelected);
    on<FilterUpdated>(_onUpdated);
  }

  final logger = Logger();
  final NativeCurl _nativeCurl = NativeCurl();
  final NativeCv _nativeCv = NativeCv();

  Completer<void>? _updateCompleter;

  Future<void> _onUpdated(
      FilterUpdated event, Emitter<FilterState> emit) async {

    final filterMap = state.data.imageFilterMap;

    final ImageFilterData filterData = event.filterData;
    filterMap[filterData.filter] = filterData.filterPath;

    emit(
      FilterLoadSuccess(
        state.data.copyWith(
          imageFilterMap: filterMap,
        ),
      ),
    );

    // _updateCompleter?.complete();
  }

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

    try {
      _nativeCv.processAllFilters(event.imagePath);
    } catch (e, stack) {
      logger.e('Apply filter error', e.toString(), stack);
    }

    final imageFilterMap = <ImageFilter, String?>{};
    for (final filter in ImageFilter.values) {
      imageFilterMap[filter] = null;
    }

    _streamSubscription ??= _nativeCv.onImageFilterComplete.listen(
      (filterData) {
        add(FilterUpdated(filterData));
      },
    );

    emit(
      FilterLoadSuccess(
        state.data.copyWith(
          imageFilterMap: imageFilterMap,
          selectionIndex: 0,
        ),
      ),
    );
  }

  Future<void> _onUpload(FilterUpload event, Emitter<FilterState> emit) async {
    if (state.data.selectionIndex == -1) {
      return;
    }

    emit(FilterBusy(state.data));

    final filter =
        state.data.imageFilterMap.keys.elementAt(state.data.selectionIndex);

    try {
      final reponseData = await _nativeCurl.postFormData(
        url: 'https://api.kraken.io/v1/upload',
        formDataList: [
          FormData(
            type: FormDataType.file,
            name: 'upload',
            value: state.data.imageFilterMap[filter]!,
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
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    _nativeCurl.init(cacertFile.path);
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
