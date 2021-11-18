import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  }

  final logger = Logger();
  final NativeCurl _nativeCurl = NativeCurl();

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

  Future<void> _onLoaded(FilterLoaded event, Emitter<FilterState> emit) async {
    await _initCurl();

    final Map<ImageFilter, String> filterMap = {};

    final path = await _localPath;
    final fileName = event.imagePath.split('/').last.split('.').first;

    for (final filter in ImageFilter.values) {
      final filterName = filter.toString().split('.').last;
      final outputPath = '$path/${fileName}_$filterName.jpg';

      try {
        await NativeCv.processImageFilter(
          ProcessImageArguments(
            outputPath: outputPath,
            inputPath: event.imagePath,
            filter: filter,
          ),
        );

        filterMap[filter] = outputPath;
      } catch (e, stack) {
        logger.e('Apply filter error', e.toString(), stack);
      }
    }

    emit(
      FilterLoadSuccess(
        state.data.copyWith(
          imageFilterMap: filterMap,
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
}
