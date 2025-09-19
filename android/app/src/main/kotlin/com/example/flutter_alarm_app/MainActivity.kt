package com.example.flutter_alarm_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	private val CHANNEL = "com.example.flutter_alarm_app/permissions"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"openExactAlarmSettings" -> {
					val opened = openExactAlarmSettings()
					result.success(opened)
				}
				"canScheduleExactAlarms" -> {
					result.success(canScheduleExactAlarms())
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun openExactAlarmSettings(): Boolean {
		return try {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
				val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
					data = Uri.parse("package:" + applicationContext.packageName)
					addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
				}
				startActivity(intent)
				true
			} else {
				false
			}
		} catch (e: Exception) {
			false
		}
	}

	private fun canScheduleExactAlarms(): Boolean {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			val am = getSystemService(android.content.Context.ALARM_SERVICE) as android.app.AlarmManager
			am.canScheduleExactAlarms()
		} else {
			true
		}
	}
}