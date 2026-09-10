package vn.kade.kade

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.time.LocalDate

/**
 * Widget "hôm nay" (plan §5.2, §5.3). Native không chạy Dart: Dart ghi `days_json`
 * (35 ngày, schema `TodayCardData.toJson`, D033/D036) qua home_widget; ở đây chỉ đọc
 * và chọn ngày == hôm nay theo giờ máy → app không mở cả tháng widget vẫn đúng.
 * Qua ngày: `HomeWidget.scheduleWidgetUpdates` (AlarmManager) + `updatePeriodMillis`.
 * Tap → app mở với `kade://open/d/<ngày>` (HomeWidgetLaunchIntent → go_router).
 */
abstract class KadeWidgetProvider(private val layout: Int, private val wide: Boolean) :
    HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val days = parseDays(widgetData.getString(KEY_DAYS, null))
    val todayIso = LocalDate.now().toString()
    val index = days.indexOfFirst { it.date == todayIso }
    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, layout)
      if (index < 0) renderEmpty(context, views) else renderDay(context, views, days, index)
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  private fun renderDay(context: Context, views: RemoteViews, days: List<DayEntry>, index: Int) {
    val d = days[index]
    val res = context.resources
    views.setTextViewText(R.id.weekday, d.weekday)
    views.setTextViewText(R.id.day, d.solarDay.toString())
    views.setTextColor(
        R.id.day,
        res.getColor(if (d.isOffDay) R.color.widget_off else R.color.widget_text, context.theme),
    )
    views.setTextViewText(R.id.month, res.getString(R.string.widget_month, d.solarMonth))
    views.setTextViewText(
        R.id.lunar,
        res.getString(
            if (d.isLeapMonth) R.string.widget_lunar_leap else R.string.widget_lunar,
            d.lunarDay,
            d.lunarMonth,
        ),
    )
    // Hôm nay có sự kiện → dòng can chi thành tên sự kiện, màu theo lớp (§5.3).
    val first = d.events.firstOrNull()
    views.setTextViewText(R.id.line5, first?.title ?: d.canChiDay)
    views.setTextColor(
        R.id.line5,
        first?.color ?: res.getColor(R.color.widget_text_secondary, context.theme),
    )
    if (wide) {
      val upcoming = ArrayList<String>()
      for (i in index + 1 until days.size) {
        for (e in days[i].events) {
          upcoming.add("• ${e.title} · ${res.getString(R.string.widget_days, i - index)}")
          if (upcoming.size == 3) break
        }
        if (upcoming.size == 3) break
      }
      val slots = intArrayOf(R.id.up1, R.id.up2, R.id.up3)
      for ((i, slot) in slots.withIndex()) {
        views.setTextViewText(
            slot,
            when {
              i < upcoming.size -> upcoming[i]
              i == 0 -> res.getString(R.string.widget_no_upcoming)
              else -> ""
            },
        )
      }
    }
    views.setOnClickPendingIntent(R.id.root, launch(context, "kade://open/d/${d.date}"))
  }

  /** Chưa có dữ liệu (chưa mở app lần nào / JSON quá cũ): số ngày theo giờ máy + nhắc mở app. */
  private fun renderEmpty(context: Context, views: RemoteViews) {
    val today = LocalDate.now()
    val res = context.resources
    views.setTextViewText(R.id.weekday, "")
    views.setTextViewText(R.id.day, today.dayOfMonth.toString())
    views.setTextColor(R.id.day, res.getColor(R.color.widget_text, context.theme))
    views.setTextViewText(R.id.month, res.getString(R.string.widget_month, today.monthValue))
    views.setTextViewText(R.id.lunar, "")
    views.setTextViewText(R.id.line5, res.getString(R.string.widget_open_to_update))
    views.setTextColor(R.id.line5, res.getColor(R.color.widget_text_secondary, context.theme))
    if (wide) {
      views.setTextViewText(R.id.up1, "")
      views.setTextViewText(R.id.up2, "")
      views.setTextViewText(R.id.up3, "")
    }
    views.setOnClickPendingIntent(R.id.root, launch(context, "kade://open/"))
  }

  private fun launch(context: Context, uri: String) =
      HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))

  companion object {
    const val KEY_DAYS = "days_json"

    fun parseDays(json: String?): List<DayEntry> {
      if (json.isNullOrEmpty()) return emptyList()
      return try {
        val arr = JSONObject(json).getJSONArray("days")
        List(arr.length()) { i ->
          val o = arr.getJSONObject(i)
          val ev = o.optJSONArray("events")
          DayEntry(
              date = o.getString("date"),
              weekday = o.getString("weekday"),
              solarDay = o.getInt("solarDay"),
              solarMonth = o.getInt("solarMonth"),
              lunarDay = o.getInt("lunarDay"),
              lunarMonth = o.getInt("lunarMonth"),
              isLeapMonth = o.optBoolean("isLeapMonth", false),
              canChiDay = o.getString("canChiDay"),
              isOffDay = o.optBoolean("isOffDay", false),
              events =
                  if (ev == null) emptyList()
                  else
                      List(ev.length()) { j ->
                        val e = ev.getJSONObject(j)
                        EventEntry(e.getString("title"), e.getLong("color").toInt())
                      },
          )
        }
      } catch (e: Exception) {
        emptyList()
      }
    }
  }
}

data class EventEntry(val title: String, val color: Int)

data class DayEntry(
    val date: String,
    val weekday: String,
    val solarDay: Int,
    val solarMonth: Int,
    val lunarDay: Int,
    val lunarMonth: Int,
    val isLeapMonth: Boolean,
    val canChiDay: String,
    val isOffDay: Boolean,
    val events: List<EventEntry>,
)

/** 2x2: thứ, số ngày, tháng, âm lịch, can chi / sự kiện. */
class KadeWidgetSmallProvider : KadeWidgetProvider(R.layout.widget_2x2, wide = false)

/** 4x2: như 2x2 + cột "Sắp tới" 3 dòng. */
class KadeWidgetWideProvider : KadeWidgetProvider(R.layout.widget_4x2, wide = true)
