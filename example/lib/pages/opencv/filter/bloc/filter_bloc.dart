import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:meta/meta.dart';

part 'filter_event.dart';

part 'filter_state.dart';

class FilterBloc extends Bloc<FilterEvent, FilterState> {
  FilterBloc()
      : super(
          const FilterLoading(
            FilterData(
              filterType: 'Normal',
              filterCategories: ['Normal', 'Cartoon'],
            ),
          ),
        ) {
    on<FilterPageChanged>(_onPageChanged);
    on<FilterCurrentImageLoaded>(_onCurrentImageLoaded);
    on<FilterCurrentImageSaved>(_onCurrentImageSaved);
  }

  Future<void> _onCurrentImageSaved(
      FilterCurrentImageSaved event, Emitter<FilterState> emit) async {
    final filterImage = state.data.filterImage;
    try {
      if (filterImage != null) {
        emit(FilterBusy(state.data));

        final now = DateTime.now();

        await ImageGallerySaver.saveImage(
          filterImage,
          quality: 100,
          name: "filter_${now.millisecondsSinceEpoch}",
        );

        emit(FilterSaveSuccess(state.data));
        return;
      }
      throw Exception('Please choose filter first!');
    } catch (e, _) {
      emit(FilterSaveFailure(data: state.data, error: e.toString()));
    }
  }

  Future<void> _onCurrentImageLoaded(
      FilterCurrentImageLoaded event, Emitter<FilterState> emit) async {
    final data = state.data;
    emit(
      FilterLoadSuccess(
        FilterData(
          filterImage: event.filterImage,
          filterType: data.filterType,
          filterCategories: data.filterCategories,
        ),
      ),
    );
  }

  Future<void> _onPageChanged(
      FilterPageChanged event, Emitter<FilterState> emit) async {
    emit(
      FilterLoadSuccess(state.data.copyWith(
        filterType: event.pageCategory,
      )),
    );
  }
}
