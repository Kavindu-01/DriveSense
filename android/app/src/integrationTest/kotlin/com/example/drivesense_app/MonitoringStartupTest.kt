package com.example.drivesense_app

import android.Manifest
import android.app.Application
import android.content.Intent
import android.os.Looper
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode
import java.time.Duration

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[35],application=DriveSenseApplication::class)
@LooperMode(LooperMode.Mode.PAUSED)
class MonitoringStartupTest {
    @Test fun armedServiceSurvivesRepeatedChecksWithoutCameraView() {
        val app=RuntimeEnvironment.getApplication()
        Shadows.shadowOf(app).grantPermissions(
            Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.POST_NOTIFICATIONS)
        SafetyStore(app).saveSettings(JSONObject().put("camera",false).put("language","en").put("uiVersion",2))
        val controller=Robolectric.buildService(MonitoringService::class.java).create()
        val service=controller.get()
        try {
            service.onStartCommand(Intent(app,MonitoringService::class.java),0,1)
            Shadows.shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(12))
            val state=JSONObject(service.snapshot())
            assertTrue(state.getBoolean("running"))
            assertEquals("off",state.getString("cameraPhase"))
            assertFalse(SafetyStore(app).history().contains("NullPointerException"))
        } finally { controller.destroy() }
    }
    @Test fun faceClientCanBeCreatedAgainWithoutDoubleInitialization() {
        val app=RuntimeEnvironment.getApplication()
        FaceClients.create(app).close()
        FaceClients.create(app).close()
    }
    @Test fun missingCameraPermissionHasARecoverableState() {
        val app=RuntimeEnvironment.getApplication()
        val controller=Robolectric.buildService(MonitoringService::class.java).create()
        try {
            val service=controller.get()
            service.retryCamera()
            assertFalse(JSONObject(service.snapshot()).optBoolean("previewStreaming"))
            assertFalse(SafetyStore(app).history().contains("NullPointerException"))
        } finally { controller.destroy() }
    }
}
