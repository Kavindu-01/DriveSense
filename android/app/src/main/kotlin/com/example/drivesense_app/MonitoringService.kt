package com.example.drivesense_app

import android.Manifest
import android.annotation.SuppressLint
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.*
import android.location.*
import android.media.*
import android.net.Uri
import android.os.*
import android.speech.tts.TextToSpeech
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleService
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.*
import com.google.mlkit.vision.face.FaceDetector
import org.json.*
import java.util.Locale
import java.util.concurrent.Executors
import kotlin.math.*

class MonitoringService : LifecycleService(), SensorEventListener, LocationListener {
    companion object { var current:MonitoringService?=null; private set }
    private val handler=Handler(Looper.getMainLooper())
    private lateinit var store:SafetyStore
    private lateinit var sensors:SensorManager
    private lateinit var locations:LocationManager
    private val executor=Executors.newSingleThreadExecutor()
    private var wake:PowerManager.WakeLock?=null
    private var tts:TextToSpeech?=null
    private var speechReady=false
    private var tone:ToneGenerator?=null
    private var provider:ProcessCameraProvider?=null
    private var analysis:ImageAnalysis?=null
    @Volatile private var cameraGeneration=0
    private var cameraRotation=android.view.Surface.ROTATION_0
    private var previewUseCase:Preview?=null
    private var orientation:android.view.OrientationEventListener?=null
    private var previewView:androidx.camera.view.PreviewView?=null
    private var detector:FaceDetector?=null
    @Volatile private var alive=true
    private val faceWork=FaceWorkGate()
    private var reopenAfter=0L
    private var lastAnalysisAt=0L
    @Volatile private var analysisRetryAt=0L
    @Volatile private var lastFrame=0L
    private var recorder:AudioRecord?=null
    private var cameraStatus="Starting"
    private var cameraPhase="idle"
    private var isArmed=false
    private var cameraStarting=false
    private var cameraStartAt=0L
    @Volatile private var lastCameraFrame=0L
    private var lastFaceAt=0L
    private var issue=""
    private var issueAt=0L
    private var lastCoverageNotice=0L
    private val problemTimes=mutableMapOf<String,Long>()
    private var audioStatus="Starting"
    private var gpsStatus="Waiting for GPS"
    private var sensorStatus="Starting"
    private var warning=""
    private var warnAt=0L
    private var audioPeak=0.0
    private var audioAt=0L
    private var gpsDropAt=0L
    private var peakG=0.0
    private var candidateAt=0L
    private var stillSince=0L
    private var linearG=0.0
    private var gyro=0.0
    private var gravity=doubleArrayOf(0.0,0.0,0.0)
    private var hasLinear=false
    private var speed=0.0
    private var location:Location?=null
    private var lastFix=0L
    private var tripId=0L
    private var tripStart=0L
    private var tripDistance=0.0
    private var topSpeed=0.0
    private var tripEvents=0
    private var tripFatigue=0
    private var validEyeSeconds=0
    private var lastEyeAt=0L
    private var movingSince=0L
    private var stoppedSince=0L
    private var autoSuppressedUntil=0L
    private var countdownEnd=0L
    private var countdownTest=false
    private var dispatchState="Not attempted"
    private var battery=100
    private var temperature=0.0
    private var charging=false
    private var thermal=0
    private var thermalListener:PowerManager.OnThermalStatusChangedListener?=null
    private var burstUntil=0L
    private var nextBurst=0L
    private var faceCount=0
    private var eyeLeft:Float?=null
    private var eyeRight:Float?=null
    private var pitch=0.0
    private var faceId:Int?=null
    private var baselinePitch:Double?=null
    private var lastNod=0L
    private var nodCount=0
    private var nodArmed=true
    private var mouthCounted=false
    private var mouthSince=0L
    private var yawnCount=0
    private var lastYawn=0L
    private var lastFatigue=0L
    private var lastDistraction=0L
    private var processedFrames=0
    private var fps=0
    private val closure=ClosureRule()
    private val hotInside=mutableSetOf<String>()
    private val earlyInside=mutableSetOf<String>()
    private var hotDistance:Double?=null
    private var hotName=""
    private var tickCount=0
    private var nodWindow=0L
    private var settings=JSONObject()
    private var hotspots=JSONArray()
    private val batteryReceiver=object:BroadcastReceiver() {
        override fun onReceive(context:Context,intent:Intent) {
            battery=intent.getIntExtra(BatteryManager.EXTRA_LEVEL,100)*100/max(1,intent.getIntExtra(BatteryManager.EXTRA_SCALE,100))
            temperature=intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE,0)/10.0
            charging=intent.getIntExtra(BatteryManager.EXTRA_PLUGGED,0)!=0
        }
    }
    override fun onCreate() {
        super.onCreate(); current=this; store=SafetyStore(this); settings=store.settings(); hotspots=store.hotspots()
        createChannels()
        orientation=object:android.view.OrientationEventListener(this) {
            override fun onOrientationChanged(degrees:Int) {
                if(degrees==ORIENTATION_UNKNOWN) return
                cameraRotation=when(degrees) { in 45..134->android.view.Surface.ROTATION_270; in 135..224->android.view.Surface.ROTATION_180; in 225..314->android.view.Surface.ROTATION_90; else->android.view.Surface.ROTATION_0 }
                analysis?.targetRotation=cameraRotation
                previewUseCase?.targetRotation=cameraRotation
            }
        }.also { if(it.canDetectOrientation()) it.enable() }
        sensors=getSystemService(SENSOR_SERVICE) as SensorManager
        locations=getSystemService(LOCATION_SERVICE) as LocationManager
        tts=TextToSpeech(this) { status -> speechReady=status==TextToSpeech.SUCCESS; if(speechReady) tts?.language=Locale.UK }
        try { tone=ToneGenerator(AudioManager.STREAM_ALARM,80) } catch(_:Exception) {}
        registerReceiver(batteryReceiver,IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        if(Build.VERSION.SDK_INT>=29) {
            thermalListener=PowerManager.OnThermalStatusChangedListener { thermal=it }
            (getSystemService(POWER_SERVICE) as PowerManager).addThermalStatusListener(thermalListener!!)
        }
    }
    override fun onStartCommand(intent:Intent?,flags:Int,id:Int):Int {
        super.onStartCommand(intent,flags,id)
        if(intent?.action=="cancel") { cancelSOS(); return START_NOT_STICKY }
        if(intent?.action=="stop") { stopSelf(); return START_NOT_STICKY }
        if(wake!=null) return START_NOT_STICKY
        try {
            var types=0
            if(granted(Manifest.permission.ACCESS_FINE_LOCATION)||granted(Manifest.permission.ACCESS_COARSE_LOCATION)) types=types or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            if(granted(Manifest.permission.CAMERA)) types=types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA
            if(granted(Manifest.permission.RECORD_AUDIO)) types=types or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            require(types!=0) { "Grant at least location, camera, or microphone permission" }
            if(Build.VERSION.SDK_INT>=29) startForeground(11,notification(words("Ready for your next trip","ඊළඟ ගමන සඳහා සූදානම්")),types) else startForeground(11,notification(words("Ready for your next trip","ඊළඟ ගමන සඳහා සූදානම්")))
            wake=(getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"DriveSense:monitor").apply { acquire(4*60*60*1000L) }
            isArmed=true
            startSensors(); startLocation(); startAudio(); nextBurst=now()
            store.event("monitoring","Real device monitoring started",null,null)
            handler.post(ticker)
        } catch(e:Exception) { isArmed=false; reportProblem("start",e); stopSelf() }
        return START_NOT_STICKY
    }
    private fun now()=SystemClock.elapsedRealtime()
    private fun granted(p:String)=checkSelfPermission(p)==PackageManager.PERMISSION_GRANTED
    private fun createChannels() {
        if(Build.VERSION.SDK_INT>=26) {
            val nm=getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(NotificationChannel("monitor",words("DriveSense checks","DriveSense පරීක්ෂා"),NotificationManager.IMPORTANCE_LOW))
            nm.createNotificationChannel(NotificationChannel("alerts",words("Safety alerts","ආරක්ෂක දැනුම්දීම්"),NotificationManager.IMPORTANCE_HIGH))
        }
    }
    private fun openIntent():PendingIntent=PendingIntent.getActivity(this,0,Intent(this,MainActivity::class.java),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun notification(text:String):Notification {
        val b=if(Build.VERSION.SDK_INT>=26) Notification.Builder(this,"monitor") else Notification.Builder(this)
        return b.setContentTitle("DriveSense").setContentText(text).setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(openIntent()).setOngoing(true)
            .addAction(Notification.Action.Builder(android.R.drawable.ic_media_pause,words("Stop","නවත්වන්න"),PendingIntent.getService(this,3,Intent(this,MonitoringService::class.java).setAction("stop"),PendingIntent.FLAG_IMMUTABLE)).build()).build()
    }
    private fun startSensors() {
        hasLinear=sensors.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)!=null
        val accel=sensors.getDefaultSensor(if(hasLinear) Sensor.TYPE_LINEAR_ACCELERATION else Sensor.TYPE_ACCELEROMETER)
        accel?.let { sensors.registerListener(this,it,SensorManager.SENSOR_DELAY_GAME) }
        sensors.getDefaultSensor(Sensor.TYPE_GYROSCOPE)?.let { sensors.registerListener(this,it,SensorManager.SENSOR_DELAY_UI) }
        sensorStatus=if(accel==null) "Accelerometer unavailable" else if(sensors.getDefaultSensor(Sensor.TYPE_GYROSCOPE)==null) "Accelerometer active • no gyro required" else "Accelerometer + gyroscope active"
    }
    override fun onAccuracyChanged(sensor:Sensor?,accuracy:Int) {}
    override fun onSensorChanged(e:SensorEvent) {
        if(!alive) return
        if(e.sensor.type==Sensor.TYPE_GYROSCOPE) {
            gyro=sqrt(e.values.take(3).sumOf { it.toDouble()*it })
            if(tripId!=0L && speed>10 && gyro>(if(settings.optString("vehicle")=="motorcycle") 2.2 else 1.5) && now()-lastDistraction>15000) {
                lastDistraction=now(); event("motion","Turning/phone-movement irregularity; not a confirmed lane change")
            }
            return
        }
        val values=e.values.take(3).mapIndexed { i,v ->
            if(hasLinear) v.toDouble() else { gravity[i]=0.85*gravity[i]+0.15*v; v-gravity[i] }
        }
        linearG=sqrt(values.sumOf { it*it })/SensorManager.GRAVITY_EARTH
        if(linearG<0.12 && speed<3) { if(stillSince==0L) stillSince=now() } else stillSince=0
        if(tripId!=0L && linearG>3.0) {
            peakG=max(peakG,linearG)
            if(candidateAt==0L) { candidateAt=now(); event("candidate","Impact candidate; checking independent signals and 30 s stillness") }
        }
    }
    @SuppressLint("MissingPermission")
    private fun startLocation() {
        if(!granted(Manifest.permission.ACCESS_FINE_LOCATION)&&!granted(Manifest.permission.ACCESS_COARSE_LOCATION)) { gpsStatus="Location permission denied"; return }
        try {
            var any=false
            for(p in listOf(LocationManager.GPS_PROVIDER,LocationManager.NETWORK_PROVIDER)) {
                if((p!=LocationManager.GPS_PROVIDER || granted(Manifest.permission.ACCESS_FINE_LOCATION)) && locations.isProviderEnabled(p)) { locations.requestLocationUpdates(p,2000L,0f,this,Looper.getMainLooper()); any=true }
            }
            gpsStatus=if(any) "Waiting for accurate position" else "Enable phone location/GPS"
        } catch(e:Exception) { gpsStatus="GPS unavailable: "+e.message }
    }
    override fun onProviderDisabled(provider:String) { gpsStatus="Location provider disabled" }
    override fun onLocationChanged(fix:Location) {
        if(!alive || fix.accuracy>50 || now()-fix.elapsedRealtimeNanos/1_000_000>15000) return
        val previous=location; val oldSpeed=speed
        if(previous!=null && fix.elapsedRealtimeNanos<=previous.elapsedRealtimeNanos) return
        location=fix; lastFix=now()
        speed=if(fix.hasSpeed()) max(0.0,fix.speed*3.6) else if(previous!=null && fix.elapsedRealtimeNanos>previous.elapsedRealtimeNanos) previous.distanceTo(fix)/((fix.elapsedRealtimeNanos-previous.elapsedRealtimeNanos)/1e9)*3.6 else 0.0
        gpsStatus="GPS ±"+fix.accuracy.toInt()+" m"
        if(previous!=null && now()-previous.elapsedRealtimeNanos/1_000_000<15000) {
            val dt=(fix.elapsedRealtimeNanos-previous.elapsedRealtimeNanos)/1e9
            if(dt in 0.5..8.0) {
                val decel=(oldSpeed-speed)/3.6/dt
                if(oldSpeed>20 && decel>4) gpsDropAt=now()
                if(tripId!=0L && decel< -3 && now()-lastDistraction>10000) { lastDistraction=now(); event("motion","GPS rapid acceleration candidate") }
                if(tripId!=0L && speed>15 && previous.hasBearing() && fix.hasBearing()) {
                    val angle=abs((fix.bearing-previous.bearing+540)%360-180)
                    val threshold=if(settings.optString("vehicle")=="motorcycle") 65 else 45
                    if(angle>threshold && now()-lastDistraction>15000) { lastDistraction=now(); event("motion","GPS heading-change irregularity; no gyro required") }
                }
                if(tripId!=0L && decel>3 && now()-lastDistraction>10000) { lastDistraction=now(); event("braking","GPS harsh braking candidate"); warn("Driving irregularity. Stay alert",false) }
            }
        }
        if(speed>8 && fix.accuracy<=30) {
            stoppedSince=0; if(movingSince==0L) movingSince=now()
            if(tripId==0L && now()-movingSince>15000 && now()>autoSuppressedUntil) startTrip()
        } else {
            movingSince=0; if(speed<3 && stoppedSince==0L) stoppedSince=now()
        }
        if(tripId!=0L) {
            if(previous!=null) {
                val d=previous.distanceTo(fix).toDouble(); val dt=(fix.elapsedRealtimeNanos-previous.elapsedRealtimeNanos)/1e9
                if(dt in 0.1..15.0 && d>max(3.0,fix.accuracy/2.0) && d/dt<60) tripDistance+=d
            }
            topSpeed=max(topSpeed,speed); store.point(tripId,fix.latitude,fix.longitude)
        }
        checkHotspots(fix)
    }
    private fun startTrip() {
        if(tripId!=0L) return
        tripId=System.currentTimeMillis(); tripStart=now(); tripDistance=0.0; topSpeed=0.0; tripEvents=0; tripFatigue=0; validEyeSeconds=0
        location?.let { store.point(tripId,it.latitude,it.longitude) }; event("trip","Trip started"); checkpoint(false)
    }
    fun toggleTrip() { if(tripId==0L) startTrip() else { finishTrip(); autoSuppressedUntil=now()+60000 } }
    private fun finishTrip() { if(tripId==0L) return; checkpoint(true); event("trip","Trip completed"); tripId=0L; candidateAt=0; peakG=0.0 }
    private fun checkpoint(complete:Boolean) {
        if(tripId==0L) return
        store.saveTrip(JSONObject().put("id",tripId).put("duration",(now()-tripStart)/1000).put("distance",tripDistance).put("topSpeed",topSpeed).put("events",tripEvents).put("fatigue",tripFatigue).put("score",max(0,100-tripEvents*3-tripFatigue*7)).put("eyeObservedSeconds",validEyeSeconds).put("complete",complete).put("vehicle",settings.optString("vehicle")))
    }
    @SuppressLint("MissingPermission")
    private fun startAudio() {
        if(!granted(Manifest.permission.RECORD_AUDIO)) { audioStatus="Microphone permission denied • reduced coverage"; return }
        try {
            val size=max(4096,AudioRecord.getMinBufferSize(16000,AudioFormat.CHANNEL_IN_MONO,AudioFormat.ENCODING_PCM_16BIT))
            val r=AudioRecord(MediaRecorder.AudioSource.MIC,16000,AudioFormat.CHANNEL_IN_MONO,AudioFormat.ENCODING_PCM_16BIT,size)
            require(r.state==AudioRecord.STATE_INITIALIZED) { "Microphone unavailable" }; recorder=r; r.startRecording(); audioStatus="Microphone active • no recordings"
            Thread({
                val b=ShortArray(2048); var baseline=0.02
                while(alive && recorder===r) {
                    val n=try { r.read(b,0,b.size) } catch(_:Exception) { -1 }
                    if(n<=0) { handler.post { audioStatus="Microphone interrupted • reduced coverage" }; break }
                    val rms=sqrt((0 until n).sumOf { b[it].toDouble()*b[it] }/n)/32768.0
                    val transient=rms>max(0.35,baseline*5); baseline=baseline*0.97+rms*0.03
                    handler.post { if(alive) { audioPeak=rms; if(transient) audioAt=now() } }
                }
            },"DriveSense-audio").start()
        } catch(e:Exception) { audioStatus="Microphone unavailable • reduced coverage"; event("coverage",e.message ?: audioStatus) }
    }
    fun attachPreview(view:androidx.camera.view.PreviewView) {
        if(previewView===view) return
        previewView=view
        if(analysis!=null) connectPreview()
        else if(!cameraStarting) nextBurst=max(now(),reopenAfter)
    }
    private fun connectPreview() {
        val view=previewView ?: return
        val a=analysis ?: return
        val cameraProvider=provider ?: return
        try {
            val existing=previewUseCase
            if(existing!=null) {
                existing.setSurfaceProvider(view.surfaceProvider)
                return
            }
            @Suppress("DEPRECATION")
            val preview=Preview.Builder().setTargetResolution(android.util.Size(640,480))
                .setTargetRotation(view.display?.rotation ?: cameraRotation).build()
            preview.setSurfaceProvider(view.surfaceProvider)
            cameraProvider.bindToLifecycle(this,CameraSelector.DEFAULT_FRONT_CAMERA,a,preview)
            previewUseCase=preview
        } catch(e:Exception) { reportProblem("preview",e) }
    }
    fun detachPreview(view:androidx.camera.view.PreviewView) {
        if(previewView!==view) return
        previewView=null
        previewUseCase?.let { preview ->
            preview.setSurfaceProvider(null)
            try { provider?.unbind(preview) } catch(e:Exception) { reportProblem("preview",e) }
        }
        previewUseCase=null
        // Keep analysis alive. The normal periodic-check policy will let it rest.
        burstUntil=now()+8000
    }
    fun ready()=isArmed
    fun refreshSettings() { val oldLanguage=settings.optString("language"); settings=store.settings(); if(oldLanguage!=settings.optString("language")) createChannels() }
    fun retryCamera(force:Boolean=false) {
        if(cameraStarting) return
        if(!force && analysis!=null) { connectPreview(); return }
        if(analysis!=null) stopCamera("Trying camera again")
        issue=""
        nextBurst=max(now(),reopenAfter)
    }
    private fun reportProblem(stage:String,e:Exception) {
        issue=stage; issueAt=now()
        android.util.Log.e("DriveSense",stage,e)
        if(now()-(problemTimes[stage] ?: -60000)>30000) {
            problemTimes[stage]=now()
            store.event("diagnostic",stage+"\n"+android.util.Log.getStackTraceString(e),null,null)
        }
    }
    private fun runCheck(stage:String,block:()->Unit) {
        try { block() } catch(e:Exception) { reportProblem(stage,e) }
    }
    private fun startCamera() {
        if(cameraStarting || analysis!=null || now()<reopenAfter) return
        if(!granted(Manifest.permission.CAMERA)) { cameraPhase="permission"; cameraStatus="Camera permission needed"; return }
        cameraGeneration++
        val generation=cameraGeneration
        cameraStarting=true; cameraStartAt=now(); lastCameraFrame=0L; lastAnalysisAt=0L
        cameraPhase="starting"; cameraStatus="Opening camera"
        closure.reset(); baselinePitch=null; faceId=null; eyeLeft=null; eyeRight=null
        try {
            if(detector==null) detector=FaceClients.create(applicationContext)
            val future=ProcessCameraProvider.getInstance(applicationContext)
            future.addListener({
                if(!alive || generation!=cameraGeneration) return@addListener
                try {
                    val cameraProvider=future.get()
                    provider=cameraProvider
                    check(cameraProvider.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)) { "No front camera available" }
                    val rotation=previewView?.display?.rotation ?: cameraRotation
                    @Suppress("DEPRECATION")
                    val a=ImageAnalysis.Builder().setTargetResolution(android.util.Size(640,480))
                        .setTargetRotation(rotation).setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST).build()
                    a.setAnalyzer(executor) { image ->
                        if(!alive || generation!=cameraGeneration) { image.close(); return@setAnalyzer }
                        val t=now()
                        lastCameraFrame=t
                        handler.post {
                            if(alive && generation==cameraGeneration && cameraStarting) {
                                cameraStarting=false
                                burstUntil=now()+8000
                                cameraStatus="Checking your face"
                                if(issue=="camera") issue=""
                            }
                        }
                        if(t-lastFrame<100 || t<analysisRetryAt || !faceWork.acquire()) { image.close(); return@setAnalyzer }
                        lastFrame=t
                        val input:InputImage
                        val faceWidth:Int
                        try {
                            val degrees=image.imageInfo.rotationDegrees
                            val bytes=CameraFrames.nv21(image.width,image.height,image.planes.map {
                                CameraFrames.Plane(it.buffer,it.rowStride,it.pixelStride)
                            })
                            faceWidth=if(degrees%180==0) image.width else image.height
                            input=InputImage.fromByteArray(bytes,image.width,image.height,degrees,android.graphics.ImageFormat.NV21)
                        } catch(e:Exception) {
                            faceWork.release()
                            handler.post { if(alive && generation==cameraGeneration) reportProblem("vision",e) }
                            return@setAnalyzer
                        } finally {
                            // Never hold a CameraX image while ML Kit loads or processes a frame.
                            image.close()
                        }
                        try {
                            detector!!.process(input).addOnSuccessListener { faces ->
                                if(alive && generation==cameraGeneration) {
                                    lastAnalysisAt=now(); processedFrames++
                                    if(issue=="vision") issue=""
                                    onFaces(faces,faceWidth)
                                }
                            }.addOnFailureListener { e ->
                                if(alive && generation==cameraGeneration) {
                                    analysisRetryAt=now()+2000
                                    cameraPhase="analysis_wait"
                                    reportProblem("vision",e)
                                }
                            }.addOnCompleteListener { faceWork.release() }
                        } catch(e:Exception) {
                            faceWork.release()
                            handler.post {
                                if(alive && generation==cameraGeneration) {
                                    analysisRetryAt=now()+2000
                                    cameraPhase="analysis_wait"
                                    reportProblem("vision",e)
                                }
                            }
                        }
                    }
                    // Bind capture first; preview is a separate optional consumer.
                    cameraProvider.bindToLifecycle(this,CameraSelector.DEFAULT_FRONT_CAMERA,a)
                    analysis=a
                    connectPreview()
                    burstUntil=now()+30000
                    cameraStatus="Waiting for the first camera image"
                } catch(e:Exception) { if(generation==cameraGeneration) failCamera(e) }
            },ContextCompat.getMainExecutor(this))
        } catch(e:Exception) { failCamera(e) }
    }
    private fun failCamera(e:Exception) {
        reportProblem("camera",e)
        stopCamera("Camera could not open")
        cameraPhase="failed"
        nextBurst=now()+15000
    }
    private fun stopCamera(status:String) {
        cameraGeneration++
        cameraStarting=false
        reopenAfter=now()+1500
        lastCameraFrame=0L; lastAnalysisAt=0L
        analysis?.clearAnalyzer()
        try { provider?.unbindAll() } catch(e:Exception) { reportProblem("camera",e) }
        analysis=null; previewUseCase=null; cameraStatus=status
        closure.reset(); eyeLeft=null; eyeRight=null; faceCount=0
        mouthSince=0; mouthCounted=false; nodArmed=true; baselinePitch=null
    }
    private fun updateCamera() {
        val tooHot=temperature>=45 || thermal>=3
        val needed=tripId!=0L || previewView!=null
        if(!settings.optBoolean("camera",true) || tooHot || !needed) {
            if(analysis!=null || cameraStarting) stopCamera("Camera is resting")
            cameraPhase=if(tooHot) "hot" else if(!settings.optBoolean("camera",true)) "off" else "idle"
            return
        }
        CameraHealth.problem(now(),analysis!=null,cameraStarting,cameraStartAt,lastCameraFrame)?.let {
            failCamera(IllegalStateException(it))
            return
        }
        // Keep the dedicated setup/check screen live; periodic checks continue during normal driving.
        if(analysis!=null && !cameraStarting && previewView==null && now()>burstUntil) {
            stopCamera("Camera resting between checks")
            cameraPhase="resting"
            nextBurst=now()+if(battery<20) 30000 else if(charging) 4000 else 12000
        } else if(analysis==null && !cameraStarting && now()>=nextBurst && now()>=reopenAfter) {
            nextBurst=now()+15000
            startCamera()
        }
        if(tripId!=0L && cameraPhase in listOf("face_missing","eyes_hidden") && now()-lastCoverageNotice>90000 && now()-cameraStartAt>4000) {
            lastCoverageNotice=now()
            warn("We cannot see your eyes clearly. Check your phone position when safe",false)
        }
    }
    private fun onFaces(faces:List<Face>,width:Int) {
        faceCount=faces.size
        if(faces.isEmpty()) { cameraPhase="face_missing"; cameraStatus="Face unavailable"; closure.observe(now(),null); eyeLeft=null; eyeRight=null; return }
        val target=when(settings.optString("driverSide","center")) { "left"->0.25; "right"->0.75; else->0.5 }
        lastFaceAt=now()
        val f=faces.minByOrNull { abs(it.boundingBox.centerX().toDouble()/width-target) }!!
        if(faceId!=f.trackingId) { closure.reset(); baselinePitch=null; faceId=f.trackingId }
        eyeLeft=f.leftEyeOpenProbability; eyeRight=f.rightEyeOpenProbability; pitch=f.headEulerAngleX.toDouble()
        val valid=eyeLeft!=null && eyeRight!=null && abs(f.headEulerAngleY)<=18
        if(valid) lastEyeAt=now()
        cameraPhase=if(valid) "checking" else "eyes_hidden"
        cameraStatus=if(valid) "Eyes/head measurable • burst active" else "Head visible • eye coverage reduced"
        if(closure.observe(now(),if(valid) eyeLeft!!<0.3 && eyeRight!!<0.3 else null) && now()-lastFatigue>5000) {
            lastFatigue=now(); tripFatigue++; event("fatigue","Prolonged eye closure >=1.5 s"); warn("Eyes closed. Stop safely and rest",true)
        }
        val base=baselinePitch
        if(base==null) baselinePitch=pitch else {
            if(abs(pitch-base)<10) { baselinePitch=base*0.98+pitch*0.02; nodArmed=true }
            if(base-pitch>18 && nodArmed && now()-lastNod>3000) {
                nodArmed=false
                if(now()-nodWindow>60000) { nodCount=0; nodWindow=now() }
                lastNod=now(); nodCount++
                if(nodCount>=2) { event("fatigue","Repeated downward head movement"); tripFatigue++; warn("Repeated head nodding. Take a break",true); nodCount=0 }
            }
        }
        val upper=f.getContour(FaceContour.UPPER_LIP_BOTTOM)?.points; val lower=f.getContour(FaceContour.LOWER_LIP_TOP)?.points
        if(upper!=null && lower!=null && upper.isNotEmpty() && lower.isNotEmpty()) {
            val gap=abs(lower.map { it.y }.average()-upper.map { it.y }.average())/max(1,f.boundingBox.height())
            if(gap>0.07) {
                if(mouthSince==0L) mouthSince=now()
                if(now()-mouthSince>1800 && !mouthCounted && now()-lastYawn>10000) {
                    mouthCounted=true
                    lastYawn=now(); yawnCount++; event("yawn","Sustained mouth-opening candidate; talking can resemble yawning")
                    if(yawnCount>=2 && (now()-lastNod<60000 || (tripId!=0L && now()-tripStart>90*60000))) warn("Possible fatigue. Stop safely for a break",false)
                }
            } else { mouthSince=0; mouthCounted=false }
        }
        if(abs(f.headEulerAngleY)>30 && now()-lastDistraction>15000) { lastDistraction=now(); event("looking_away","Head turned away; logged without alarm") }
    }
    private val ticker=object:Runnable {
        override fun run() {
            if(!alive) return
            try { tick() } catch(e:Exception) { reportProblem("monitor",e) }
            handler.postDelayed(this,1000)
        }
    }
    private fun tick() {
        tickCount++
        if(tripId!=0L && now()-lastEyeAt<600) validEyeSeconds++
        if(tickCount%5==0) runCheck("storage") { settings=store.settings(); hotspots=store.hotspots(); checkpoint(false) }
        fps=processedFrames; processedFrames=0
        if(lastFix!=0L && now()-lastFix>15000) { speed=0.0; gpsStatus="GPS stale • no current speed"; movingSince=0; stoppedSince=0 }
        if(tripId!=0L && stoppedSince!=0L && now()-stoppedSince>180000 && candidateAt==0L && countdownEnd==0L) finishTrip()
        if(tripId!=0L && candidateAt==0L && countdownEnd==0L && gpsDropAt!=0L && audioAt!=0L && abs(gpsDropAt-audioAt)<4000 && now()-gpsDropAt<8000) {
            candidateAt=gpsDropAt; event("candidate","Coincident GPS/audio candidate; checking post-event stillness")
        }
        if(candidateAt!=0L && countdownEnd==0L) {
            val gps=abs(gpsDropAt-candidateAt)<8000 && gpsDropAt!=0L
            val audio=abs(audioAt-candidateAt)<4000 && audioAt!=0L
            val still=stillSince!=0L && now()-stillSince>=30000
            if(CrashFusion.qualifies(peakG>=3.0,gps,audio,still) && (still || CrashFusion.strongOverride(peakG,gps,audio))) { beginCountdown(false); candidateAt=0; peakG=0.0 }
            else if(now()-candidateAt>90000) { event("candidate_cleared","Crash candidate expired without sufficient evidence"); candidateAt=0; peakG=0.0 }
        }
        if(countdownEnd!=0L) {
            if(now()>=countdownEnd) { countdownEnd=0; dispatch() }
            else if(ceil((countdownEnd-now())/1000.0).toInt()%5==0) tone?.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD,400)
        }
        runCheck("camera") { updateCamera() }
        if(tickCount%10==0) runCheck("notification") {
            (getSystemService(NOTIFICATION_SERVICE) as? NotificationManager)?.notify(11,
                notification(if(countdownEnd!=0L) words("Please respond to the emergency alert","හදිසි පණිවිඩයට ප්‍රතිචාර දක්වන්න")
                    else if(tripId!=0L) words("Driving","ගමන අතරතුර")+" • "+speed.toInt()+" km/h"
                    else words("Ready to notice your next trip","ඊළඟ ගමන හඳුනාගැනීමට සූදානම්")))
        }
        runCheck("power") { wake?.let { if(!it.isHeld) it.acquire(4*60*60*1000L) } }

    }
    private fun checkHotspots(fix:Location) {
        hotDistance=null; hotName=""
        for(i in 0 until hotspots.length()) {
            val h=hotspots.getJSONObject(i); val dist=FloatArray(1)
            Location.distanceBetween(fix.latitude,fix.longitude,h.getDouble("latitude"),h.getDouble("longitude"),dist)
            val d=dist[0].toDouble(); val id=h.getString("id")
            if(hotDistance==null || d<hotDistance!!) { hotDistance=d; hotName=h.getString("name") }
            if(tripId==0L || fix.accuracy>30) continue
            if(d<=100 && hotInside.add(id)) { event("hotspot","Entered 100 m: "+h.getString("name")); warn("Crash hotspot within one hundred metres. Take care",false) }
            if(d>140) hotInside.remove(id)
            val early=max(150.0,speed/3.6*12)
            if(d>100 && d<=early && speed>15 && earlyInside.add(id)) warn("Approaching a known crash hotspot",false)
            if(d>early+50) earlyInside.remove(id)
        }
    }
    private fun event(type:String,message:String) {
        store.event(type,message,location?.latitude,location?.longitude,tripId)
        if(tripId!=0L && type in listOf("braking","motion")) tripEvents++
    }
    fun warn(message:String,critical:Boolean) {
        if(!critical && now()-warnAt<20000) return
        warning=message; warnAt=now()
        tone?.startTone(if(critical) ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD else ToneGenerator.TONE_PROP_BEEP,if(critical) 1800 else 300)
        @Suppress("DEPRECATION")
        val vibrator=getSystemService(VIBRATOR_SERVICE) as Vibrator
        if(Build.VERSION.SDK_INT>=26) vibrator.vibrate(VibrationEffect.createOneShot(if(critical) 1200 else 300,VibrationEffect.DEFAULT_AMPLITUDE)) else vibrator.vibrate(500)
        if(speechReady) tts?.speak(message,TextToSpeech.QUEUE_FLUSH,Bundle().apply { putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME,settings.optDouble("volume",0.8).toFloat()) },"warning")
        val b=if(Build.VERSION.SDK_INT>=26) Notification.Builder(this,"alerts") else Notification.Builder(this)
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(12,b.setContentTitle("DriveSense").setContentText(SafetyWords.translate(message,settings.optString("language","en"))).setSmallIcon(android.R.drawable.ic_dialog_alert).setContentIntent(openIntent()).setAutoCancel(true).build())
    }
    fun beginCountdown(test:Boolean) {
        if(countdownEnd!=0L) return
        countdownTest=test; countdownEnd=now()+settings.optInt("countdown",30).coerceIn(15,60)*1000L
        dispatchState=if(test) "TEST countdown — no live 119 destination" else "Awaiting driver cancellation"
        event(if(test) "test_countdown" else "sos_countdown",dispatchState)
        warn(if(test) "Test emergency countdown. Press I'm OK to cancel" else "Possible crash. Press I'm OK if you are safe",true)
        val cancel=PendingIntent.getService(this,4,Intent(this,MonitoringService::class.java).setAction("cancel"),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val b=if(Build.VERSION.SDK_INT>=26) Notification.Builder(this,"alerts") else Notification.Builder(this)
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(13,b.setContentTitle(words("Are you safe?","ඔබ ආරක්ෂිතද?")).setContentText(words("Open DriveSense to respond","ප්‍රතිචාර දැක්වීමට DriveSense විවෘත කරන්න")).setSmallIcon(android.R.drawable.ic_dialog_alert).setContentIntent(openIntent()).setOngoing(true).addAction(Notification.Action.Builder(android.R.drawable.ic_media_pause,words("I am safe","මම ආරක්ෂිතයි"),cancel).build()).build())
    }
    fun cancelSOS() {
        countdownEnd=0; candidateAt=0; peakG=0.0; stillSince=0; dispatchState="Cancelled • monitoring continues"
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(13)
        tone?.stopTone(); tts?.stop(); event("sos_cancelled",dispatchState)
    }
    @SuppressLint("MissingPermission")
    private fun dispatch() {
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(13)
        if(!settings.optBoolean("autoDispatch",false)) { dispatchState="Not sent: automatic test dispatch disabled"; event("dispatch",dispatchState); return }
        val loc=location
        val coordinates=if(loc==null) "location unavailable" else "https://maps.google.com/?q="+loc.latitude+","+loc.longitude+" (fix age "+(now()-lastFix)/1000+"s)"
        val englishMessage=(if(countdownTest) "DriveSense TEST" else "DriveSense suspected crash")+": "+settings.optString("name")+"; "+settings.optString("vehicle")+" "+settings.optString("plate")+"; callback "+settings.optString("phone")+"; time "+java.util.Date()+"; "+coordinates
        val message=if(settings.optString("smsLanguage","en")=="si")
            (if(countdownTest) "DriveSense පරීක්ෂණ පණිවිඩය" else "DriveSense: අනතුරක් සිදුවී ඇති බවට සැකයක්")+
            ": "+settings.optString("name")+"; වාහනය "+settings.optString("plate")+"; අමතන්න "+settings.optString("phone")+"; වේලාව "+java.util.Date()+"; "+coordinates
            else englishMessage
        val targets=linkedSetOf<String>(); val contact=settings.optString("contact").replace(" ","")
        if(contact.matches(Regex("\\+?[0-9]{9,15}"))) targets.add(contact)
        targets.add("placeholder")
        val outcomes=mutableListOf<String>()
        if(granted(Manifest.permission.SEND_SMS)) {
            @Suppress("DEPRECATION")
            val sms=if(Build.VERSION.SDK_INT>=31) getSystemService(android.telephony.SmsManager::class.java) else android.telephony.SmsManager.getDefault()
            for(number in targets) try { sms.sendMultipartTextMessage(number,null,sms.divideMessage(message),null,null); outcomes.add("SMS submitted (delivery unknown)") }
                catch(e:Exception) { outcomes.add("SMS failed: "+e.message) }
        } else outcomes.add("SMS permission missing")
        try {
            if(granted(Manifest.permission.CALL_PHONE)) {
                startActivity(Intent(Intent.ACTION_CALL,Uri.parse("tel:placeholder")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                outcomes.add("Personal test call requested; connection not verified")
            } else outcomes.add("Call permission missing; use test dialler")
        } catch(e:Exception) { outcomes.add("Call blocked; open app and use test dialler") }
        dispatchState=outcomes.joinToString(" • "); event("dispatch",dispatchState); warn("Emergency test dispatch attempted. Check status",false)
    }
    private fun words(en:String,si:String)=if(settings.optString("language","en")=="si") si else en
    fun snapshot():String {
        val remaining=if(countdownEnd==0L) -1 else max(0,ceil((countdownEnd-now())/1000.0).toInt())
        return JSONObject().put("running",isArmed).put("tripActive",tripId!=0L).put("speed",speed).put("gForce",linearG).put("gyro",gyro)
            .put("gpsStatus",gpsStatus).put("sensorStatus",sensorStatus).put("audioStatus",audioStatus).put("audioPeak",audioPeak)
            .put("cameraStatus",cameraStatus).put("cameraPhase",cameraPhase)
            .put("cameraWait",if(cameraPhase=="resting" || cameraPhase=="failed") max(0,ceil((nextBurst-now())/1000.0).toInt()) else 0)
            .put("previewStreaming",previewView?.previewStreamState?.value==androidx.camera.view.PreviewView.StreamState.STREAMING)
            .put("frameAge",if(lastCameraFrame==0L) -1 else now()-lastCameraFrame)
            .put("analysisAge",if(lastAnalysisAt==0L) -1 else now()-lastAnalysisAt)
            .put("cameraGeneration",cameraGeneration).put("previewAttached",previewView!=null)
            .put("faceAge",if(lastFaceAt==0L) -1 else now()-lastFaceAt)
            .put("issue",if(now()-issueAt<30000) issue else "").put("faces",faceCount).put("leftEye",eyeLeft ?: JSONObject.NULL).put("rightEye",eyeRight ?: JSONObject.NULL)
            .put("pitch",pitch).put("fps",fps).put("yawns",yawnCount).put("distance",tripDistance).put("duration",if(tripId==0L) 0 else (now()-tripStart)/1000)
            .put("score",max(0,100-tripEvents*3-tripFatigue*7)).put("battery",battery).put("temperature",temperature).put("charging",charging)
            .put("warning",if(now()-warnAt<15000) warning else "").put("countdown",remaining).put("candidate",candidateAt!=0L)
            .put("dispatch",dispatchState).put("latitude",location?.latitude ?: JSONObject.NULL).put("longitude",location?.longitude ?: JSONObject.NULL)
            .put("hotspots",hotspots).put("nearestDistance",hotDistance ?: JSONObject.NULL).put("nearestName",hotName)
            .put("route",if(tripId==0L) JSONArray() else store.route(tripId)).toString()
    }
    override fun onDestroy() {
        alive=false; isArmed=false; orientation?.disable(); handler.removeCallbacksAndMessages(null); finishTrip(); sensors.unregisterListener(this)
        try { locations.removeUpdates(this) } catch(_:Exception) {}
        try { recorder?.stop(); recorder?.release() } catch(_:Exception) {}; recorder=null
        stopCamera("Stopped"); detector?.close(); executor.shutdown(); tts?.stop(); tts?.shutdown(); tone?.release()
        try { unregisterReceiver(batteryReceiver) } catch(_:Exception) {}
        if(wake?.isHeld==true) wake?.release(); wake=null
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(13)
        if(Build.VERSION.SDK_INT>=29) thermalListener?.let { (getSystemService(POWER_SERVICE) as PowerManager).removeThermalStatusListener(it) }
        current=null; store.close(); super.onDestroy()
    }
}
