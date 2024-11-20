package com.example.testapp


import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setLocale("Ru_ru") 
        MapKitFactory.setApiKey("d7f59100-0a23-48bb-8816-753f19414af2") 
    }
}
