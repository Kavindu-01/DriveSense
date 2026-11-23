package com.example.drivesense_app

import java.nio.ByteBuffer
import org.junit.Assert.*
import org.junit.Test

class CameraFramesTest {
    private fun plane(bytes:ByteArray,row:Int,pixel:Int,offset:Int=0):CameraFrames.Plane {
        val b=ByteBuffer.wrap(bytes); b.position(offset)
        return CameraFrames.Plane(b,row,pixel)
    }
    @Test fun packsPlanarYuvAsNv21() {
        val output=CameraFrames.nv21(4,2,listOf(
            plane(byteArrayOf(1,2,3,4,5,6,7,8),4,1),
            plane(byteArrayOf(10,11),2,1),plane(byteArrayOf(20,21),2,1)))
        assertArrayEquals(byteArrayOf(1,2,3,4,5,6,7,8,20,10,21,11),output)
    }
    @Test fun handlesPaddingInterleavedChromaAndNonzeroBufferPosition() {
        val y=plane(byteArrayOf(99,1,2,3,4,99,99,5,6,7,8),6,1,1)
        val u=plane(byteArrayOf(99,10,99,11),4,2,1)
        val v=plane(byteArrayOf(99,20,99,21),4,2,1)
        assertArrayEquals(byteArrayOf(1,2,3,4,5,6,7,8,20,10,21,11),CameraFrames.nv21(4,2,listOf(y,u,v)))
        assertEquals(1,y.buffer.position())
    }
    @Test fun copiedFrameDoesNotDependOnReleasedCameraBuffer() {
        val data=byteArrayOf(1,2,3,4)
        val copy=CameraFrames.nv21(2,2,listOf(plane(data,2,1),plane(byteArrayOf(10),1,1),plane(byteArrayOf(20),1,1)))
        data.fill(0)
        assertEquals(1,copy[0].toInt())
    }
    @Test fun oldInferenceBlocksNewGenerationUntilCompletion() {
        val work=FaceWorkGate()
        assertTrue(work.acquire())
        // A camera restart cannot bypass an outstanding ML task.
        assertFalse(work.acquire())
        work.release()
        assertTrue(work.acquire())
        assertFalse(work.acquire())
        work.release()
    }
    @Test fun reopeningAfterLongRestDoesNotFailBeforeBinding() {
        assertNull(CameraHealth.problem(90000,false,false,1000,0))
        assertNull(CameraHealth.problem(91000,true,true,90000,0))
        assertNull(CameraHealth.problem(92000,true,false,90000,92000))
    }
    @Test fun captureCanRemainHealthyWhileDetectorLoads() {
        for(t in 1000L..60000L step 1000) {
            assertNull(CameraHealth.problem(t,true,false,0,t))
        }
    }
    @Test fun genuinelyMissingCaptureEventuallyRequiresRecovery() {
        assertNotNull(CameraHealth.problem(31001,true,true,1000,0))
        assertNotNull(CameraHealth.problem(22000,true,false,1000,11000))
        assertNull(CameraHealth.problem(22000,false,false,1000,11000))
    }
}
