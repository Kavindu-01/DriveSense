package com.example.drivesense_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val safetyStore by lazy { SafetyStore(this) }
    private var permissionResult: MethodChannel.Result? = null
    private var importResult: MethodChannel.Result? = null
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        engine.platformViewsController.registry.registerViewFactory("drivesense/camera", DriverPreviewFactory())
        MethodChannel(engine.dartExecutor.binaryMessenger, "drivesense/device").setMethodCallHandler { call, result ->
            try {
                val store = safetyStore
                when(call.method) {
                    "snapshot" -> result.success(MonitoringService.current?.snapshot() ?: store.idleSnapshot())
                    "permissions" -> {
                        if(permissionResult != null) { result.error("busy","Request already open",null); return@setMethodCallHandler }
                        permissionResult=result
                        val p=mutableListOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION,Manifest.permission.RECORD_AUDIO)
                        if(call.argument<Boolean>("camera")!=false) p.add(Manifest.permission.CAMERA)
                        if(Build.VERSION.SDK_INT>=33) p.add(Manifest.permission.POST_NOTIFICATIONS)
                        requestPermissions(p.toTypedArray(),81)
                    }
                    "dispatchPermissions" -> {
                        if(permissionResult != null) { result.error("busy","Request already open",null); return@setMethodCallHandler }
                        permissionResult=result
                        requestPermissions(arrayOf(Manifest.permission.SEND_SMS,Manifest.permission.CALL_PHONE),81)
                    }
                    "start" -> {
                        val intent=Intent(this,MonitoringService::class.java)
                        if(Build.VERSION.SDK_INT>=26) startForegroundService(intent) else startService(intent)
                        val main=android.os.Handler(android.os.Looper.getMainLooper())
                        var attempts=0
                        val check=object:Runnable {
                            override fun run() {
                                if(MonitoringService.current?.ready()==true) result.success(true)
                                else if(++attempts>=10) result.error("start","Safety checks could not start. Review permissions.",null)
                                else main.postDelayed(this,300)
                            }
                        }
                        main.postDelayed(check,100)
                    }
                    "retryCamera" -> { MonitoringService.current?.retryCamera(call.argument<Boolean>("force") == true); result.success(MonitoringService.current != null) }
                    "shareReport" -> { shareReport(); result.success(true) }
                    "osmAttribution" -> { startActivity(Intent(Intent.ACTION_VIEW,Uri.parse("https://www.openstreetmap.org/copyright"))); result.success(true) }
                    "stop" -> { stopService(Intent(this,MonitoringService::class.java)); result.success(true) }
                    "trip" -> { MonitoringService.current?.toggleTrip(); result.success(true) }
                    "cancel" -> { MonitoringService.current?.cancelSOS(); result.success(true) }
                    "alarm" -> { MonitoringService.current?.warn("Readiness check. DriveSense alarm is working",true); result.success(MonitoringService.current != null) }
                    "testCountdown" -> { MonitoringService.current?.beginCountdown(true); result.success(MonitoringService.current != null) }
                    "history" -> result.success(store.history())
                    "route" -> result.success(store.route((call.arguments as Number).toLong()).toString())
                    "settings" -> result.success(store.settings().toString())
                    "saveSettings" -> {
                        val json=JSONObject(call.arguments as String)
                        json.put("testDestination","placeholder")
                        store.saveSettings(json); MonitoringService.current?.refreshSettings(); result.success(true)
                    }
                    "importHotspots" -> {
                        if(importResult != null) { result.error("busy","Import already open",null); return@setMethodCallHandler }
                        importResult=result
                        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply { type="*/*"; addCategory(Intent.CATEGORY_OPENABLE) },82)
                    }
                    "appSettings" -> { startActivity(Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:"+packageName))); result.success(true) }
                    "dialTest" -> { startActivity(Intent(Intent.ACTION_DIAL,Uri.parse("tel:placeholder"))); result.success(true) }
                    "deleteHistory" -> {
                        if(MonitoringService.current != null) result.error("active","Stop monitoring before deleting",null)
                        else { store.clearHistory(); result.success(true) }
                    }
                    else -> result.notImplemented()
                }
            } catch(e:Exception) { result.error("device",e.message,null) }
        }
    }
    override fun onRequestPermissionsResult(code:Int,permissions:Array<out String>,grants:IntArray) {
        super.onRequestPermissionsResult(code,permissions,grants)
        if(code==81) { permissionResult?.success(permissions.associateWith { checkSelfPermission(it)==PackageManager.PERMISSION_GRANTED }); permissionResult=null }
    }
    override fun onActivityResult(code:Int,resultCode:Int,data:Intent?) {
        super.onActivityResult(code,resultCode,data)
        if(code==82) {
            try {
                if(resultCode!=RESULT_OK || data?.data==null) importResult?.success("Import cancelled")
                else {
                    val content=contentResolver.openInputStream(data.data!!)?.use { input ->
                        val out=java.io.ByteArrayOutputStream(); val buffer=ByteArray(8192)
                        while(true) { val n=input.read(buffer); if(n<0) break; require(out.size()+n<=1_000_000) { "File exceeds 1 MB" }; out.write(buffer,0,n) }
                        out.toString("UTF-8")
                    } ?: error("Could not open file")
                    importResult?.success(storeImport(content))
                }
            } catch(e:Exception) { importResult?.error("import",e.message,null) }
            importResult=null
        }
    }
    private fun shareReport() {
        val report=JSONObject().put("appVersion","1.2.1").put("device",android.os.Build.MODEL)
            .put("android",android.os.Build.VERSION.RELEASE).put("sdk",android.os.Build.VERSION.SDK_INT)
            .put("history",JSONObject(safetyStore.history()))
            .put("snapshot",JSONObject(MonitoringService.current?.snapshot() ?: safetyStore.idleSnapshot()))
        val directory=java.io.File(cacheDir,"reports").apply { mkdirs() }
        val file=java.io.File(directory,"DriveSense-report.json").apply { writeText(report.toString(2)) }
        val uri=androidx.core.content.FileProvider.getUriForFile(this,packageName+".reports",file)
        val send=Intent(Intent.ACTION_SEND).setType("application/json").putExtra(Intent.EXTRA_STREAM,uri)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val si=safetyStore.settings().optString("language")=="si"
        startActivity(Intent.createChooser(send,if(si) "වාර්තාව බෙදාගන්න" else "Share DriveSense report"))
    }
    private fun storeImport(content:String)=SafetyStore(this).importHotspots(content)
}
