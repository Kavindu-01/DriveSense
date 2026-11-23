package com.example.drivesense_app
import android.content.Context
import com.google.mlkit.common.MlKit
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions

object FaceClients {
    fun create(context:Context):FaceDetector {
        val options=FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
            .setContourMode(FaceDetectorOptions.CONTOUR_MODE_ALL)
            .setMinFaceSize(0.2f).build()
        return try { FaceDetection.getClient(options) }
        catch(e:IllegalStateException) {
            // Normal startup is handled by MlKitInitProvider. Public initialize() is NOT idempotent.
            if(e.message?.contains("has not been initialized")!=true) throw e
            MlKit.initialize(context.applicationContext)
            FaceDetection.getClient(options)
        }
    }
}
