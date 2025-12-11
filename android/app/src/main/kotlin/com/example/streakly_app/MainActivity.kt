package com.example.Streakly

import android.app.AlarmManager
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "streakly/permissions"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"canScheduleExactAlarms" -> {
					val alarmManager = getSystemService(AlarmManager::class.java)
					val canSchedule = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
						alarmManager?.canScheduleExactAlarms() ?: false
					} else {
						true
					}
					result.success(canSchedule)
				}
				"requestScheduleExactAlarm" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
						try {
							val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
							intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
							startActivity(intent)
							result.success(true)
						} catch (e: Exception) {
							result.error("ERROR", "Failed to launch exact alarm settings: ${e.message}", null)
						}
					} else {
						result.success(true)
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
