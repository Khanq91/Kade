package vn.kade.kade

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.time.LocalDate

/**
 * Widget "hôm nay" (plan §5.2, §5.3). Native không chạy Dart: Dart ghi `days_json`
 * (35 ngày, schema `TodayCardData.toJson` + theme, D033/D036/D045) qua home_widget; ở đây chỉ đọc
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
    val json = widgetData.getString(KEY_DAYS, null)
    val days = parseDays(json)
    val colors = widgetColors(context, json)
    val todayIso = LocalDate.now().toString()
    val index = days.indexOfFirst { it.date == todayIso }
    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, layout)
      applyColors(views, colors)
      if (index < 0) renderEmpty(context, views, colors)
      else renderDay(context, views, days, index, colors)
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  private fun applyColors(views: RemoteViews, colors: WidgetColors) {
    views.setInt(R.id.widget_bg_tint, "setColorFilter", colors.accent)
    views.setInt(R.id.widget_disc_tint, "setColorFilter", colors.surface)
    if (wide) views.setInt(R.id.widget_panel_tint, "setColorFilter", colors.surface)
    views.setTextColor(R.id.weekday, colors.onAccent)
    views.setTextColor(R.id.day, colors.text)
    views.setTextColor(R.id.month, colors.muted)
    views.setTextColor(R.id.lunar_label, colors.onAccent)
    views.setTextColor(R.id.lunar_day, colors.onAccent)
    views.setTextColor(R.id.lunar_month, colors.onAccent)
    views.setTextColor(R.id.line5, colors.onAccent)
  }

  private fun renderDay(
      context: Context,
      views: RemoteViews,
      days: List<DayEntry>,
      index: Int,
      colors: WidgetColors,
  ) {
    val d = days[index]
    val res = context.resources
    views.setTextViewText(R.id.weekday, d.weekday)
    views.setTextViewText(R.id.day, d.solarDay.toString())
    views.setTextColor(R.id.day, if (d.isOffDay) colors.offText else colors.text)
    views.setTextViewText(R.id.month, res.getString(R.string.widget_month, d.solarMonth))
    views.setTextViewText(R.id.lunar_day, d.lunarDay.toString())
    views.setTextViewText(
        R.id.lunar_month,
        res.getString(
            if (d.isLeapMonth) R.string.widget_lunar_month_leap else R.string.widget_month,
            d.lunarMonth,
        ),
    )
    // Hôm nay có sự kiện → dòng can chi thành tên sự kiện, màu theo lớp (§5.3).
    val first = d.events.firstOrNull()
    views.setTextViewText(R.id.line5, first?.title ?: d.canChiDay)
    views.setTextColor(
        R.id.line5,
        first?.color ?: colors.onAccent,
    )
    if (wide) {
      val upcoming = ArrayList<Pair<DayEntry, EventEntry>>()
      for (i in index + 1 until days.size) {
        for (e in days[i].events) {
          upcoming.add(days[i] to e)
          if (upcoming.size == 3) break
        }
        if (upcoming.size == 3) break
      }
      renderUpcoming(context, views, upcoming, colors)
    }
    views.setOnClickPendingIntent(R.id.root, launch(context, "kade://open/d/${d.date}"))
  }

  /** Chưa có dữ liệu (chưa mở app lần nào / JSON quá cũ): số ngày theo giờ máy + nhắc mở app. */
  private fun renderEmpty(context: Context, views: RemoteViews, colors: WidgetColors) {
    val today = LocalDate.now()
    val res = context.resources
    views.setTextViewText(R.id.weekday, "")
    views.setTextViewText(R.id.day, today.dayOfMonth.toString())
    views.setTextColor(R.id.day, colors.text)
    views.setTextViewText(R.id.month, res.getString(R.string.widget_month, today.monthValue))
    views.setTextViewText(R.id.lunar_label, res.getString(R.string.widget_open_short))
    views.setTextViewText(R.id.lunar_day, "")
    views.setTextViewText(R.id.lunar_month, "")
    views.setTextViewText(R.id.line5, res.getString(R.string.widget_update_short))
    views.setTextColor(R.id.line5, colors.onAccent)
    if (wide) {
      renderUpcoming(context, views, emptyList(), colors)
      views.setTextViewText(R.id.up_title1, res.getString(R.string.widget_open_to_update))
    }
    views.setOnClickPendingIntent(R.id.root, launch(context, "kade://open/"))
  }

  private fun renderUpcoming(
      context: Context,
      views: RemoteViews,
      upcoming: List<Pair<DayEntry, EventEntry>>,
      colors: WidgetColors,
  ) {
    val rows = intArrayOf(R.id.up_row1, R.id.up_row2, R.id.up_row3)
    val tags = intArrayOf(R.id.up_tag1, R.id.up_tag2, R.id.up_tag3)
    val dates = intArrayOf(R.id.up_date1, R.id.up_date2, R.id.up_date3)
    val dots = intArrayOf(R.id.up_dot1, R.id.up_dot2, R.id.up_dot3)
    val titles = intArrayOf(R.id.up_title1, R.id.up_title2, R.id.up_title3)
    val res = context.resources
    for (i in rows.indices) {
      views.setTextColor(titles[i], colors.text)
      views.setViewVisibility(
          rows[i],
          if (i < upcoming.size || (i == 0 && upcoming.isEmpty())) View.VISIBLE else View.GONE,
      )
      if (i >= upcoming.size) {
        if (i == 0) {
          views.setViewVisibility(tags[i], View.GONE)
          views.setViewVisibility(dates[i], View.GONE)
          views.setViewVisibility(dots[i], View.GONE)
          views.setTextViewText(titles[i], res.getString(R.string.widget_no_upcoming))
        }
        continue
      }
      val (day, event) = upcoming[i]
      val lunar = event.type == "lunar"
      views.setViewVisibility(tags[i], View.VISIBLE)
      views.setViewVisibility(dates[i], View.VISIBLE)
      views.setViewVisibility(dots[i], View.VISIBLE)
      views.setTextViewText(
          tags[i],
          res.getString(if (lunar) R.string.widget_tag_lunar else R.string.widget_tag_solar),
      )
      views.setTextColor(tags[i], if (lunar) colors.accentText else colors.secondaryText)
      views.setTextViewText(dates[i], "${day.weekday} ${day.solarDay}/${day.solarMonth}")
      views.setTextColor(dates[i], colors.accentText)
      views.setTextColor(dots[i], event.color)
      views.setTextViewText(titles[i], event.title)
    }
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
                        EventEntry(
                            e.getString("title"),
                            e.optString("type", "solar"),
                            e.getLong("color").toInt(),
                        )
                      },
          )
        }
      } catch (e: Exception) {
        emptyList()
      }
    }
  }
}

private data class WidgetColors(
    val accent: Int,
    val surface: Int,
    val text: Int,
    val muted: Int,
    val accentText: Int,
    val onAccent: Int,
    val secondaryText: Int,
    val offText: Int,
)

private fun widgetColors(context: Context, json: String?): WidgetColors {
  val res = context.resources
  val fallback = WidgetColors(
      accent = res.getColor(R.color.widget_accent, context.theme),
      surface = res.getColor(R.color.widget_surface, context.theme),
      text = res.getColor(R.color.widget_text, context.theme),
      muted = res.getColor(R.color.widget_text_secondary, context.theme),
      accentText = res.getColor(R.color.widget_accent_text, context.theme),
      onAccent = res.getColor(R.color.widget_on_accent, context.theme),
      secondaryText = res.getColor(R.color.widget_solar_tag_text, context.theme),
      offText = res.getColor(R.color.widget_off, context.theme),
  )
  if (json.isNullOrEmpty()) return fallback
  return try {
    val theme = JSONObject(json).getJSONObject("theme")
    val systemDark =
        res.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES
    val dark = when (theme.getString("mode")) {
      "dark" -> true
      "light" -> false
      else -> systemDark
    }
    val set = theme.getJSONObject(if (dark) "dark" else "light")
    WidgetColors(
        accent = set.getLong("ac").toInt(),
        surface = set.getLong("sf").toInt(),
        text = set.getLong("tx").toInt(),
        muted = set.getLong("mu").toInt(),
        accentText = set.getLong("acT").toInt(),
        onAccent = set.getLong("on").toInt(),
        secondaryText = set.getLong("bT").toInt(),
        offText = set.getLong("offT").toInt(),
    )
  } catch (e: Exception) {
    fallback
  }
}

data class EventEntry(val title: String, val type: String, val color: Int)

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
