package com.example.drivesense_app
import android.content.Context
import android.view.View
import androidx.camera.view.PreviewView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class DriverPreviewFactory:PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context:Context,id:Int,args:Any?):PlatformView {
        val view=PreviewView(context).apply {
            implementationMode=PreviewView.ImplementationMode.COMPATIBLE
            scaleType=PreviewView.ScaleType.FILL_CENTER
        }
        var disposed=false
        val attach=object:Runnable {
            override fun run() {
                if(disposed || !view.isAttachedToWindow) return
                if(view.width==0 || view.height==0) { view.postDelayed(this,100); return }
                val service=MonitoringService.current
                if(service!=null) service.attachPreview(view) else view.postDelayed(this,250)
            }
        }
        view.addOnAttachStateChangeListener(object:View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v:View) { view.post(attach) }
            override fun onViewDetachedFromWindow(v:View) {
                view.removeCallbacks(attach)
                // Flutter may temporarily detach a platform view during composition.
                // Only dispose ends this preview lease.
            }
        })
        return object:PlatformView {
            override fun getView():View=view
            override fun dispose() {
                disposed=true; view.removeCallbacks(attach)
                MonitoringService.current?.detachPreview(view)
            }
        }
    }
}
