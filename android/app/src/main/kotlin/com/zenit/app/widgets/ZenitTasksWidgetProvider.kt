package com.zenit.app.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.zenit.app.R

class ZenitTasksWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val PREFERENCES_NAME = "HomeWidgetPreferences"
        private const val TITLE_KEY = "tasks_widget_title"
        private const val BODY_KEY = "tasks_widget_body"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    private fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
        val title = prefs.getString(TITLE_KEY, "ZENiT Tasks") ?: "ZENiT Tasks"
        val body =
            prefs.getString(BODY_KEY, "Widget locked. Upgrade to ZENiT Pro.")
                ?: "Widget locked. Upgrade to ZENiT Pro."

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.zenit_tasks_widget)
            views.setTextViewText(R.id.zenit_tasks_widget_title, title)
            views.setTextViewText(R.id.zenit_tasks_widget_body, body)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
