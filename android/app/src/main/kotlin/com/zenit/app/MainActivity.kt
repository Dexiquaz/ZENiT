package com.zenit.app

import android.content.pm.ActivityInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val ORIENTATION_CHANNEL = "zenit/orientation"
		private const val METHOD_SET_AMBIENT_ROTATION_OVERRIDE = "setAmbientRotationOverride"
		private const val METHOD_CLEAR_AMBIENT_ROTATION_OVERRIDE = "clearAmbientRotationOverride"
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			ORIENTATION_CHANNEL,
		).setMethodCallHandler { call, result ->
			when (call.method) {
				METHOD_SET_AMBIENT_ROTATION_OVERRIDE -> {
					requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR
					result.success(null)
				}
				METHOD_CLEAR_AMBIENT_ROTATION_OVERRIDE -> {
					requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
					result.success(null)
				}
				else -> result.notImplemented()
			}
		}
	}
}
