package com.sangcv.ffi_flutter.model

import android.graphics.Bitmap

enum class ImageFilter {
    ORIGINAL, GREY,
}

data class ImageFilterData(
    val bitmap: Bitmap,
    val imageFilter: ImageFilter,
    val duoTomeParam: DuoTomeParam
)
