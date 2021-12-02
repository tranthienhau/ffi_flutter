package com.sangcv.camera_filter.activities

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Matrix
import android.media.ThumbnailUtils
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import com.sangcv.ffi_flutter.ImageFilterUtils
import com.sangcv.ffi_flutter.adapter.ImageFilterAction
import com.sangcv.ffi_flutter.adapter.ImageFilterAdapter
import com.sangcv.ffi_flutter.camera.PortraitCameraBridgeViewBase
import com.sangcv.ffi_flutter.databinding.CameraFilterBinding
import com.sangcv.ffi_flutter.model.DuoTomeParam
import com.sangcv.ffi_flutter.model.ImageFilter
import com.sangcv.ffi_flutter.model.ImageFilterData
import org.opencv.android.Utils
import org.opencv.core.Mat
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit


class CameraFilterActivity : AppCompatActivity(),
    PortraitCameraBridgeViewBase.CvCameraViewListener2 {
    private val tag = "CameraFilterActivity:"

    private lateinit var imageFilterAdapter: ImageFilterAdapter
    private lateinit var mOpenCvCameraView: PortraitCameraBridgeViewBase

    private var firstBitmap: Bitmap? = null

    private var duoTomeParam: DuoTomeParam? = null


    @RequiresApi(Build.VERSION_CODES.M)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val binding = CameraFilterBinding.inflate(layoutInflater)
        val context = applicationContext
        mOpenCvCameraView = binding.cameraView
        mOpenCvCameraView.cameraIndex = PortraitCameraBridgeViewBase.CAMERA_ID_BACK
        mOpenCvCameraView.setCvCameraViewListener(this)
        setContentView(binding.root)
        imageFilterAdapter = ImageFilterAdapter(
            thumbnailFilters, object : ImageFilterAction {
                override fun onClick(imageFilter: ImageFilterData) {

                    duoTomeParam = imageFilter.duoTomeParam
                }
            }
        )
        val layoutManager =
            LinearLayoutManager(binding.root.context, LinearLayoutManager.HORIZONTAL, false)

        binding.rvParticipate.adapter = imageFilterAdapter
        binding.rvParticipate.layoutManager = layoutManager
        binding.changeCameraButton.setOnClickListener {
            mOpenCvCameraView.disableView()

            when (mOpenCvCameraView.cameraIndex) {
                PortraitCameraBridgeViewBase.CAMERA_ID_FRONT -> mOpenCvCameraView.cameraIndex =
                    PortraitCameraBridgeViewBase.CAMERA_ID_BACK
                PortraitCameraBridgeViewBase.CAMERA_ID_BACK -> mOpenCvCameraView.cameraIndex =
                    PortraitCameraBridgeViewBase.CAMERA_ID_FRONT
                else -> mOpenCvCameraView.cameraIndex = PortraitCameraBridgeViewBase.CAMERA_ID_BACK
            }

            firstBitmap = null
            mOpenCvCameraView.enableView()
        }

        if (checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // Permission is not granted
            // Should we show an explanation?
            if (shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)) {
                // Show some text
                Toast.makeText(context, "Need access to your camera to proceed", Toast.LENGTH_LONG)
                    .show()
                finish()
            } else {
                // No explanation needed; request the permission
                requestPermissions(
                    arrayOf(Manifest.permission.CAMERA),
                    MY_PERMISSIONS_REQUEST_CAMERA
                )
            }
        } else {
            mOpenCvCameraView.enableView()
        }

    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (!grantResults.contains(PackageManager.PERMISSION_DENIED) && requestCode == MY_PERMISSIONS_REQUEST_CAMERA) {
            mOpenCvCameraView.enableView()
        }

        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onCameraViewStarted(width: Int, height: Int) {
        val TAG = java.lang.StringBuilder(tag).append("onCameraViewStarted").toString()

        Log.i(TAG, "OpenCV CameraView Started")
    }

    override fun onCameraViewStopped() {
        val TAG = java.lang.StringBuilder(tag).append("onCameraViewStarted").toString()

        Log.i(TAG, "OpenCV CameraView Stopped")
    }

    private val thumbnailFilters: MutableList<ImageFilterData> = mutableListOf()
    private fun createFilterThumbnails(bitmap: Bitmap) {
        val exponents = listOf(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0)
        val s1List = listOf(0, 1, 2)
        val s2List = listOf(0, 1, 2, 3)
        val s3List = listOf(1, 0)

        val thumbnailBitmap = ThumbnailUtils.extractThumbnail(bitmap, 100, 100)

        var degrees = 0f // rotation degree
        when (mOpenCvCameraView.cameraIndex) {
            PortraitCameraBridgeViewBase.CAMERA_ID_FRONT -> degrees = 270f
            PortraitCameraBridgeViewBase.CAMERA_ID_BACK -> degrees = 90f
        }

        val matrix = Matrix()

        matrix.setRotate(degrees)

        val rotateBitmap = Bitmap.createBitmap(
            thumbnailBitmap,
            0,
            0,
            thumbnailBitmap.width,
            thumbnailBitmap.height,
            matrix,
            true
        )

        thumbnailFilters.clear()
        for (s1 in s1List) {
            for (s2 in s2List) {
                for (s3 in s3List) {
                    for (exponent in exponents) {

                        val rgbFrameBitmap =
                            Bitmap.createBitmap(
                                rotateBitmap.width,
                                rotateBitmap.height,
                                Bitmap.Config.ARGB_8888
                            )
                        val param = DuoTomeParam(
                            exponent = exponent, s1 = s1, s2 = s2, s3 = s3
                        )

                        ImageFilterUtils.applyDuoToneFilter(
                            rotateBitmap, rgbFrameBitmap, param
                        )

                        thumbnailFilters.add(
                            ImageFilterData(
                                bitmap = rgbFrameBitmap, imageFilter = ImageFilter.GREY,
                                duoTomeParam = param
                            )
                        )
                    }

                }
            }
        }

        runOnUiThread {
            imageFilterAdapter.notifyDataSetChanged()
        }

    }

    override fun onCameraFrame(inputFrame: PortraitCameraBridgeViewBase.CvCameraViewFrame): Mat {
        val mat = inputFrame.rgba()

        if (firstBitmap == null) {
            try {

                firstBitmap =
                    Bitmap.createBitmap(mat.width(), mat.height(), Bitmap.Config.ARGB_8888)

                Utils.matToBitmap(mat, firstBitmap)


                val executor: ScheduledExecutorService =
                    Executors.newSingleThreadScheduledExecutor()
                executor.schedule({
                    createFilterThumbnails(firstBitmap!!)
                }, 0, TimeUnit.MILLISECONDS)
            } catch (e: Exception) {
                Log.i("Thumbnail error", e.toString())
            }
        }


        duoTomeParam?.apply {
            ImageFilterUtils.applyDuoToneFilterJNI(
                mat.nativeObjAddr, this
            )
        }


        return mat
    }

    companion object {
        private const val MY_PERMISSIONS_REQUEST_CAMERA = 1337
        private fun checkSelfPermission(context: Context, permission: String?): Int {
            requireNotNull(permission) { "permission is null" }
            return context.checkPermission(permission, Process.myPid(), Process.myUid())
        }

        // Used to load the 'native-lib' and 'opencv' libraries on application startup.
        init {
            System.loadLibrary("native-lib")
        }
    }
}