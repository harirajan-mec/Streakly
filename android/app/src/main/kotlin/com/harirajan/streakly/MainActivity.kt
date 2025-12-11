package com.harirajan.streakly

import android.app.AlarmManager
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import org.json.JSONObject

class MainActivity : FlutterActivity() {
	private val CHANNEL = "streakly/permissions"
	private val WIDGET_CHANNEL = "com.streakly.app/widget"

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

		// Widget channel to receive calls from Dart and update AppWidget
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"updateWidget" -> {
					val args = call.arguments as? Map<*, *>
					if (args != null) {
						val streakCount = (args["streakCount"] as? Number)?.toInt() ?: 0
						val todayCompleted = args["todayCompleted"] as? Boolean ?: false
						val habitName = args["habitName"] as? String ?: "Streakly"
						val nextReminder = args["nextReminder"] as? String ?: ""
						val habitColor = (args["habitColor"] as? Number)?.toInt() ?: -1
						val habitIcon = (args["habitIcon"] as? Number)?.toInt() ?: -1
						val mode = args["mode"] as? String ?: "all"
						val habitId = args["habitId"] as? String
						val calendar = (args["calendar"] as? List<*>)?.mapNotNull { item ->
							(item as? Map<*, *>)?.let { map ->
								val day = map["day"] as? String
								val done = map["done"] as? Boolean ?: false
								if (day != null) mapOf("day" to day, "done" to done) else null
							}
						} ?: emptyList()
						// Persist to SharedPreferences for widget to read
						val prefs = getSharedPreferences("streakly_widget", Context.MODE_PRIVATE)
						prefs.edit()
							.putInt("streakCount", streakCount)
							.putBoolean("todayCompleted", todayCompleted)
							.putString("habitName", habitName)
							.putString("nextReminder", nextReminder)
							.putInt("habitColor", habitColor)
							.putInt("habitIcon", habitIcon)
							.putString("mode", mode)
							.putString("habitId", habitId)
							.putString("calendar", JSONObject(mapOf("days" to calendar)).toString())
							.apply()

						// Trigger widget update
						val appWidgetManager = AppWidgetManager.getInstance(this)
						val thisWidget = ComponentName(this, StreaklyWidgetProvider::class.java)
						val ids = appWidgetManager.getAppWidgetIds(thisWidget)
						if (ids != null && ids.isNotEmpty()) {
							val updateIntent = Intent(this, StreaklyWidgetProvider::class.java)
							updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
							updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
							sendBroadcast(updateIntent)
						}
						result.success(true)
					} else {
						result.error("BAD_ARGS", "Arguments map expected", null)
					}
				}
				"refreshWidget" -> {
					val appWidgetManager = AppWidgetManager.getInstance(this)
					val thisWidget = ComponentName(this, StreaklyWidgetProvider::class.java)
					val ids = appWidgetManager.getAppWidgetIds(thisWidget)
					if (ids != null && ids.isNotEmpty()) {
						val updateIntent = Intent(this, StreaklyWidgetProvider::class.java)
						updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
						updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
						sendBroadcast(updateIntent)
					}
					result.success(true)
				}
				// progress widget functions removed (progress ring widget deleted)
				"clearWidgetData" -> {
					val prefs = getSharedPreferences("streakly_widget", Context.MODE_PRIVATE)
					prefs.edit().clear().apply()
					result.success(true)
				}
				"getWidgetData" -> {
					val prefs = getSharedPreferences("streakly_widget", Context.MODE_PRIVATE)
					val obj = JSONObject()
					obj.put("streakCount", prefs.getInt("streakCount", 0))
					obj.put("todayCompleted", prefs.getBoolean("todayCompleted", false))
					obj.put("habitName", prefs.getString("habitName", "Streakly"))
					obj.put("nextReminder", prefs.getString("nextReminder", ""))
					obj.put("habitColor", prefs.getInt("habitColor", -1))
					obj.put("mode", prefs.getString("mode", "all"))
					obj.put("habitId", prefs.getString("habitId", null))
					obj.put("habitIcon", prefs.getInt("habitIcon", -1))
					result.success(mapOf(
						"streakCount" to obj.getInt("streakCount"),
						"todayCompleted" to obj.getBoolean("todayCompleted"),
						"habitName" to obj.getString("habitName"),
						"nextReminder" to obj.getString("nextReminder"),
						"habitColor" to obj.getInt("habitColor"),
						"mode" to obj.getString("mode"),
						"habitId" to obj.optString("habitId", null)
					))
				}
				else -> result.notImplemented()
			}
		}
	}
}
