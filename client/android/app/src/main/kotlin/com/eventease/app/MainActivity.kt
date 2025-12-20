package com.eventease.app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge mode for Android 15+ compliance
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
