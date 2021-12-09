import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:ffi_flutter_example/services/image/image_transfer_service.dart';
import 'package:ffi_flutter_example/services/image/tensorflow_transfer_service.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

part 'transfer_filter_event.dart';

part 'transfer_filter_state.dart';

class TransferFilterBloc
    extends Bloc<TransferFilterEvent, TransferFilterState> {
  TransferFilterBloc({ImageTransferService? imageTransferService})
      : super(TransferFilterLoading()) {
    _imageTransferService = imageTransferService ?? TensorflowTransferService();

    on<TransferFilterLoaded>(_onLoaded);
    on<TransferFilterImageStyleLoaded>(_onImageStyleLoaded);
    on<TransferFilterBlendChanged>(_onBlendChanged);
  }

  final logger = Logger();
  late final ImageTransferService _imageTransferService;

  Future<Uint8List> _readFileByte(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    File audioFile = File.fromUri(myUri);
    Uint8List bytes = await audioFile.readAsBytes();
    return bytes;
  }

  Future<void> _onBlendChanged(
    TransferFilterBlendChanged event,
    Emitter<TransferFilterState> emit,
  ) async {
    final data = state.data;
    if (data != null && data.transferImageList.isNotEmpty) {
      emit(
        TransferFilterLoadSuccess(data.copyWith(
          transferImage: data.transferImageList[event.blend],
          blend: event.blend.toDouble(),
        )),
      );
    }
  }

  Future<void> _onLoaded(
    TransferFilterLoaded event,
    Emitter<TransferFilterState> emit,
  ) async {
    await _imageTransferService.init();
    final imageByteData = await _readFileByte(event.imagePath);
    final bytes = imageByteData.buffer.asUint8List();

    await _imageTransferService.loadImage(bytes);
    emit(
      TransferFilterLoadSuccess(
        TransferFilterData(
          originImage: bytes,
          blend: 0,
          transferImageList: [],
        ),
      ),
    );
  }

  CancelableOperation? cancellableOperation;

  Completer<void>? _transferConpleter;

  bool _isCancel = false;

  Future<void> _onImageStyleLoaded(
    TransferFilterImageStyleLoaded event,
    Emitter<TransferFilterState> emit,
  ) async {
    final data = state.data;
    if (data == null) {
      return;
    }
    _isCancel = true;
    await _transferConpleter?.future;

    Uint8List? originImage = data.originImage;
    _isCancel = false;
    emit(
      TransferFilterBusy(
        data.copyWith(
          stylePath: event.stylePath,
        ),
      ),
    );

    await cancellableOperation?.cancel();


    cancellableOperation = CancelableOperation.fromFuture(
      Future.microtask(() async {
        try {
          final styleImageByteData = await rootBundle.load(event.stylePath);
          final styleBytes = styleImageByteData.buffer.asUint8List();

          await _imageTransferService.selectStyle(styleBytes);

          final List<Uint8List> transferList = [];
          for (int i = 0; i <= 10; i++) {
            _transferConpleter = Completer<void>();
            final transferImage = await _imageTransferService.transfer(
                originImage, (10 - i) / 10.0);
            print('transferImage: $i');
            transferList.add(transferImage!);
            _transferConpleter?.complete();
            if(_isCancel){
              _isCancel = false;
              return;
            }
          }

          if (transferList.isNotEmpty) {
            emit(
              TransferFilterLoadSuccess(data.copyWith(
                transferImage: transferList.first,
                transferImageList: transferList,
                blend: 0,
                stylePath: event.stylePath,
              )),
            );
          }
        } catch (e, stack) {
          logger.e('TransferFilterStyleLoadFailure', e.toString(), stack);
          emit(
            TransferFilterStyleLoadFailure(
              data: data.copyWith(
                blend: 0,
                stylePath: event.stylePath,
              ),
              error: e.toString(),
            ),
          );
        }
      }),
    );

    await cancellableOperation?.value;
  }
}
