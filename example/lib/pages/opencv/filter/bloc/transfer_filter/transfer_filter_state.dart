part of 'transfer_filter_bloc.dart';

class TransferFilterData {
  const TransferFilterData({
    required this.originImage,
    this.transferImage,
    this.styleImage,
    required this.transferImageList,
    this.stylePath,
    required this.blend,
  });

  TransferFilterData copyWith({
    Uint8List? originImage,
    Uint8List? transferImage,
    Uint8List? styleImage,
    List<Uint8List>? transferImageList,
    String? stylePath,
    double? blend,
  }) {
    return TransferFilterData(
      originImage: originImage ?? this.originImage,
      transferImage: transferImage ?? this.transferImage,
      styleImage: styleImage ?? this.styleImage,
      transferImageList: transferImageList ?? this.transferImageList,
      stylePath: stylePath ?? this.stylePath,
      blend: blend ?? this.blend,
    );
  }

  final Uint8List originImage;
  final Uint8List? transferImage;
  final Uint8List? styleImage;
  final List<Uint8List> transferImageList;
  final String? stylePath;
  final double blend;
}

@immutable
abstract class TransferFilterState {
  const TransferFilterState([this.data]);

  final TransferFilterData? data;
}

class TransferFilterLoading extends TransferFilterState {}

class TransferFilterBusy extends TransferFilterState {
  const TransferFilterBusy(TransferFilterData data) : super(data);
}

class TransferFilterLoadSuccess extends TransferFilterState {
  const TransferFilterLoadSuccess(TransferFilterData data) : super(data);
}

class TransferFilterStyleLoadFailure extends TransferFilterState {
  const TransferFilterStyleLoadFailure(
      {required TransferFilterData data, required this.error})
      : super(data);

  final String error;
}
