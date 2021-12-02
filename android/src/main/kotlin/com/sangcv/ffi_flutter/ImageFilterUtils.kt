package com.sangcv.ffi_flutter

import android.graphics.Bitmap
import android.opengl.GLES20
import com.sangcv.ffi_flutter.model.DuoTomeParam
import java.nio.IntBuffer

class ImageFilterUtils {

    companion object {

        init {
            System.loadLibrary("native-lib")
        }

        external fun applyDuoToneFilter(srcBitMap: Bitmap, targetBitmap: Bitmap, param: DuoTomeParam)

        external fun applyDuoToneFilterJNI(matAddr: Long, param: DuoTomeParam)
        private fun convertMatToBitmap(x: Int, y: Int, w: Int, h: Int): Bitmap {
            val b = IntArray(w * (y + h))
            val bt = IntArray(w * h)
            val ib = IntBuffer.wrap(b)
            ib.position(0)
            GLES20.glReadPixels(0, 0, w, h, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, ib)
            var i = 0
            var k = 0
            while (i < h) {
                //remember, that OpenGL bitmap is incompatible with Android bitmap
                //and so, some correction need.
                for (j in 0 until w) {
                    val pix = b[i * w + j]
                    val pb = pix shr 16 and 0xff
                    val pr = pix shl 16 and 0x00ff0000
                    val pix1 = pix and -0xff0100 or pr or pb
                    bt[(h - k - 1) * w + j] = pix1
                }
                i++
                k++
            }
            return Bitmap.createBitmap(bt, w, h, Bitmap.Config.ARGB_8888)
        }
    }
}