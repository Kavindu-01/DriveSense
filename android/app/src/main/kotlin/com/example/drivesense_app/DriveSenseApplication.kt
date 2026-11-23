package com.example.drivesense_app

import android.app.Application
import androidx.camera.camera2.Camera2Config
import androidx.camera.core.CameraXConfig

/** Explicit CameraX configuration avoids manifest/reflection-dependent discovery. */
class DriveSenseApplication : Application(), CameraXConfig.Provider {
    override fun getCameraXConfig():CameraXConfig = Camera2Config.defaultConfig()
}
