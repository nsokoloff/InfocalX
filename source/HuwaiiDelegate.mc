using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Complications;
using Toybox.Math;
using Toybox.System;
using Toybox.Lang;

// Tap handling: touching a data field on the watch face opens the app/glance
// that Garmin associates with that data type (same as the stock watch faces).
class HuwaiiDelegate extends WatchUi.WatchFaceDelegate {

	// Long labels of the companion apps' complications (see companions/*/resources/strings).
	hidden const APP_CLOCK = "Infocal Clock";

	// Angular position (degrees, 0 = 3 o'clock, clockwise) of each arc field and its setting key.
	hidden const ARC_FIELDS = [
		[270, "comp12h"],
		[330, "comp2h"],
		[30, "comp4h"],
		[90, "comp6h"],
		[150, "comp8h"],
		[210, "comp10h"]
	];

	function initialize() {
		WatchFaceDelegate.initialize();
	}

	function onPress(clickEvent) {
		if (!(Toybox has :Complications)) {
			return false;
		}
		var coords = clickEvent.getCoordinates();
		var dx = coords[0] - centerX;
		var dy = coords[1] - centerY;
		var radius = Math.sqrt(dx*dx + dy*dy);

		var complicationType = null;
		var digitalZone = digitalTimeZone(coords[0], coords[1]);
		if (digitalZone != null) {
			complicationType = digitalZone;
		} else if (radius >= 0.68*centerX) {
			complicationType = typeForArc(Math.toDegrees(Math.atan2(dy, dx)));
		} else if (dy < -0.28*centerY) {
			complicationType = typeForBar("compbart", "compgrapht");
		} else if (dy > 0.28*centerY) {
			complicationType = typeForBar("compbarb", "compgraphb");
		} else {
			// the big number in the middle: Infocal Clock app (seconds + stopwatch), else the calendar
			complicationType = APP_CLOCK;
		}

		if (complicationType == null) {
			return false;
		}
		var candidates = [complicationType];
		if (complicationType.equals(APP_CLOCK)) {
			candidates.add(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS);
		}
		for (var i = 0; i < candidates.size(); i++) {
			try {
				var id = (candidates[i] instanceof Lang.String) ? findPublishedId(candidates[i]) : findComplicationId(candidates[i]);
				if (id != null) {
					Complications.exitTo(id);
					return true;
				}
			} catch (ex) {
				// no app is associated with this complication, try the next candidate
			}
		}
		return false;
	}

	// Companion apps (companions/ folder) publish a complication; find it by its long label.
	hidden function findPublishedId(label) {
		var iterator = Complications.getComplications();
		var complication = iterator.next();
		while (complication != null) {
			try {
				if (complication.getType() == Complications.COMPLICATION_TYPE_INVALID
						&& complication.longLabel != null
						&& complication.longLabel.toString().equals(label)) {
					return complication.complicationId;
				}
			} catch (ex) {
				// skip complications that refuse to answer
			}
			complication = iterator.next();
		}
		return null;
	}

	// Small number at the top right of the big digital styles (notifications) and the date above it (calendar).
	hidden function digitalTimeZone(x, y) {
		var app = Application.getApp();
		if (app.getProperty("use_analog")) {
			return null;
		}
		var style = app.getProperty("digital_style");
		if (style != 0 && style != 2) {
			return null;
		}
		var infoX = app.getProperty("left_digital_info") ? 0.4*centerX : 1.6*centerX;
		if ((x - infoX).abs() > 0.32*centerX) {
			return null;
		}
		if ((y - 0.7*centerY).abs() < 0.17*centerY) {
			return Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT;
		}
		if ((y - 0.4*centerY).abs() < 0.12*centerY) {
			return Complications.COMPLICATION_TYPE_CALENDAR_EVENTS;
		}
		return null;
	}

	// exitTo() needs the system's own Id object for a complication (an Id built by hand
	// crashes on the watch), so look it up in the list of complications the device offers.
	hidden function findComplicationId(type) {
		try {
			var iterator = Complications.getComplications();
			var complication = iterator.next();
			while (complication != null) {
				try {
					if (complication.getType() == type) {
						return complication.complicationId;
					}
				} catch (ex) {
					// published (third party) complications can refuse getType(); skip them
				}
				complication = iterator.next();
			}
		} catch (ex) {
			// fall through to the direct id below
		}
		return new Complications.Id(type);
	}

	// Pick the arc field whose sector contains the tapped angle.
	hidden function typeForArc(degrees) {
		if (degrees < 0) {
			degrees += 360;
		}
		var best = null;
		var bestDiff = 361;
		for (var i = 0; i < ARC_FIELDS.size(); i++) {
			var diff = (degrees - ARC_FIELDS[i][0]).abs();
			if (diff > 180) {
				diff = 360 - diff;
			}
			if (diff < bestDiff) {
				bestDiff = diff;
				best = ARC_FIELDS[i];
			}
		}
		return typeForField(Application.getApp().getProperty(best[1]));
	}

	// Top/bottom area: the data bar wins, otherwise fall back to the graph shown there.
	hidden function typeForBar(barKey, graphKey) {
		var type = typeForField(Application.getApp().getProperty(barKey));
		if (type != null) {
			return type;
		}
		var graph = Application.getApp().getProperty(graphKey);
		if (graph == 1) {
			return Complications.COMPLICATION_TYPE_HEART_RATE;
		} else if (graph == 2) {
			return Complications.COMPLICATION_TYPE_ALTITUDE;
		} else if (graph == 3) {
			return Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE;
		} else if (graph == 4) {
			return Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE;
		}
		return null;
	}

	// Map this watch face's field types to Garmin complication types (null = nothing to open).
	hidden function typeForField(field) {
		if (field == FIELD_TYPE_HEART_RATE) {
			return Complications.COMPLICATION_TYPE_HEART_RATE;
		} else if (field == FIELD_TYPE_CALORIES) {
			return Complications.COMPLICATION_TYPE_CALORIES;
		} else if (field == FIELD_TYPE_STEP) {
			return Complications.COMPLICATION_TYPE_STEPS;
		} else if (field == FIELD_TYPE_ACTIVE) {
			return Complications.COMPLICATION_TYPE_INTENSITY_MINUTES;
		} else if (field == FIELD_TYPE_DATE || field == FIELD_TYPE_WEEKCOUNT || field == FIELD_TYPE_TIME
				|| field == FIELD_TYPE_TIME_SECONDARY || field == FIELD_TYPE_AMPM_INDICATOR) {
			return Complications.COMPLICATION_TYPE_DATE;
		} else if (field == FIELD_TYPE_DISTANCE || field == FIELD_TYPE_MOVE) {
			// no distance/move complication exists; distance comes from steps
			return Complications.COMPLICATION_TYPE_STEPS;
		} else if (field == FIELD_TYPE_NOTIFICATIONS || field == FIELD_TYPE_GROUP_NOTI) {
			return Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT;
		} else if (field == FIELD_TYPE_ALTITUDE) {
			return Complications.COMPLICATION_TYPE_ALTITUDE;
		} else if (field == FIELD_TYPE_TEMPERATURE) {
			return Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE;
		} else if (field == FIELD_TYPE_SUNRISE_SUNSET) {
			return Complications.COMPLICATION_TYPE_SUNRISE;
		} else if (field == FIELD_TYPE_FLOOR) {
			return Complications.COMPLICATION_TYPE_FLOORS_CLIMBED;
		} else if (field == FIELD_TYPE_DISTANCE_WEEK) {
			return Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE;
		} else if (field == FIELD_TYPE_BAROMETER) {
			return Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE;
		} else if (field == FIELD_TYPE_WEATHER || field == FIELD_TYPE_WIND || field == FIELD_TYPE_TEMPERATURE_OUT) {
			return Complications.COMPLICATION_TYPE_CURRENT_WEATHER;
		} else if (field == FIELD_TYPE_TEMPERATURE_HL) {
			return Complications.COMPLICATION_TYPE_HIGH_LOW_TEMPERATURE;
		}
		return null;
	}
}
