package com.example.drivesense_app

import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

/** Copies strided YUV planes before CameraX's buffer is released. No images are retained. */
object CameraFrames {
    data class Plane(val buffer:ByteBuffer,val rowStride:Int,val pixelStride:Int)
    fun nv21(width:Int,height:Int,planes:List<Plane>):ByteArray {
        require(width%2==0 && height%2==0 && planes.size==3)
        val output=ByteArray(width*height*3/2)
        var index=0
        fun value(p:Plane,x:Int,y:Int)=p.buffer.get(p.buffer.position()+y*p.rowStride+x*p.pixelStride)
        for(y in 0 until height) for(x in 0 until width) output[index++]=value(planes[0],x,y)
        for(y in 0 until height/2) for(x in 0 until width/2) {
            output[index++]=value(planes[2],x,y)
            output[index++]=value(planes[1],x,y)
        }
        return output
    }
}

/** An old detector task must finish before any new camera generation submits work. */
class FaceWorkGate {
    private val busy=AtomicBoolean(false)
    fun acquire()=busy.compareAndSet(false,true)
    fun release() { busy.set(false) }
}

object CameraHealth {
    // PreviewView's UI state and detector completion are not capture-health signals.
    fun problem(now:Long,bound:Boolean,starting:Boolean,startedAt:Long,lastFrame:Long):String? = when {
        starting && now-startedAt>30000 -> "Camera opened without delivering frames within 30 seconds"
        bound && !starting && lastFrame>0 && now-lastFrame>10000 -> "Camera frame stream stalled"
        else -> null
    }
}
