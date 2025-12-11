package com.harirajan.streakly

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.Date

class StreaklyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val appWidgetManager = AppWidgetManager.getInstance(context)
        if (intent.action == ACTION_REFRESH_AND_OPEN) {
            // When widget is tapped we refresh its contents and open the main app.
            val thisWidget = android.content.ComponentName(context, StreaklyWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(thisWidget)
            for (id in ids) updateAppWidget(context, appWidgetManager, id)

            try {
                // Launch main activity
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (launchIntent != null) context.startActivity(launchIntent)
            } catch (_: Exception) {
                // ignore
            }
            return
        }

        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = android.content.ComponentName(context, StreaklyWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(thisWidget)
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("streakly_widget", Context.MODE_PRIVATE)
            // Ensure default widget mode is 'all' so the widget will show aggregated streaks
            if (!prefs.contains("mode")) {
                prefs.edit().putString("mode", "all").apply()
            }
            if (!prefs.contains("initialized")) {
                // Mark that the widget was initialized; the widget will show placeholder numbers ('-') until the app populates calendar data.
                prefs.edit().putBoolean("initialized", true).apply()
            }
            val streakCount = prefs.getInt("streakCount", 0)
            val todayCompleted = prefs.getBoolean("todayCompleted", false)
            val nextReminder = prefs.getString("nextReminder", "") ?: ""
            val habitName = prefs.getString("habitName", "") ?: ""
            val habitColor = prefs.getInt("habitColor", -1)
            val habitIcon = prefs.getInt("habitIcon", -1)
            val calendarJson = prefs.getString("calendar", "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.widget_streakly)

            // Make the widget clickable: tapping will refresh widget and open the app
            try {
                val refreshIntent = Intent(context, StreaklyWidgetProvider::class.java)
                refreshIntent.action = ACTION_REFRESH_AND_OPEN
                val pending = android.app.PendingIntent.getBroadcast(
                    context,
                    0,
                    refreshIntent,
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) android.app.PendingIntent.FLAG_MUTABLE else 0
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            } catch (_: Exception) {
                // ignore pending intent failures
            }

            // Set month name (e.g., "December 2025") based on current date
            try {
                val sdf = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
                val monthName = sdf.format(Date())
                views.setTextViewText(R.id.widget_month, monthName)
            } catch (_: Exception) {
                // ignore
            }

            // Show check icon if completed
            views.setViewVisibility(R.id.widget_completed_icon, if (todayCompleted) android.view.View.VISIBLE else android.view.View.GONE)

            // Habit name: simply show it if available (no icon displayed in widget)
            if (habitName.isNotBlank()) {
                views.setTextViewText(R.id.widget_habit_name, habitName)
                views.setViewVisibility(R.id.widget_habit_name, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_habit_name, android.view.View.GONE)
            }

            applyCalendar(views, calendarJson)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private const val ACTION_REFRESH_AND_OPEN = "com.harirajan.streakly.ACTION_REFRESH_AND_OPEN"

        // No icon mapping helper functions required — widget intentionally does not show habit icon.

        private fun applyCalendar(views: RemoteViews, calendarJson: String) {
            // Expecting JSON: {"days":[{"day":"1","done":true}, ...]} (all days in month)
            try {
                val daysArray = org.json.JSONObject(calendarJson).optJSONArray("days") ?: return
                val dayIds = listOf(
                    R.id.day1, R.id.day2, R.id.day3, R.id.day4, R.id.day5, R.id.day6, R.id.day7,
                    R.id.day8, R.id.day9, R.id.day10, R.id.day11, R.id.day12, R.id.day13, R.id.day14,
                    R.id.day15, R.id.day16, R.id.day17, R.id.day18, R.id.day19, R.id.day20, R.id.day21,
                    R.id.day22, R.id.day23, R.id.day24, R.id.day25, R.id.day26, R.id.day27, R.id.day28,
                    R.id.day29, R.id.day30, R.id.day31, R.id.day32, R.id.day33, R.id.day34, R.id.day35
                )

                for (i in dayIds.indices) {
                    val viewId = dayIds[i]
                    if (i < daysArray.length()) {
                        val obj = daysArray.optJSONObject(i) ?: continue
                        val label = obj.optString("day", (i + 1).toString()).ifBlank { (i + 1).toString() }
                        val done = obj.optBoolean("done", false)
                        views.setTextViewText(viewId, label)
                        val backgroundRes = if (done) R.drawable.widget_day_done else R.drawable.widget_day_todo
                        views.setInt(viewId, "setBackgroundResource", backgroundRes)
                        views.setTextColor(viewId, 0xFFFFFFFF.toInt())
                    } else {
                        // Unused cells for months < 35 days
                        views.setTextViewText(viewId, "")
                        views.setInt(viewId, "setBackgroundColor", 0x00000000)
                        views.setTextColor(viewId, 0xFFFFFFFF.toInt())
                    }
                }
            } catch (_: Exception) {
                // ignore parsing errors; leave defaults
            }
        }
    }
}
