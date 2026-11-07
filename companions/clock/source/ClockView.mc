using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Timer;
using Toybox.Lang;

// Tap / start button: start -> stop -> reset. Back: exit.
class ClockView extends WatchUi.View {

	var mTimer = null;
	var mRunning = false;
	var mStartedAt = 0;
	var mElapsed = 0;

	function initialize() {
		View.initialize();
	}

	function onShow() {
		mTimer = new Timer.Timer();
		mTimer.start(method(:onTick), 100, true);
	}

	function onHide() {
		if (mTimer != null) {
			mTimer.stop();
			mTimer = null;
		}
	}

	function onTick() {
		WatchUi.requestUpdate();
	}

	function toggleStopwatch() {
		if (mRunning) {
			mElapsed += System.getTimer() - mStartedAt;
			mRunning = false;
		} else if (mElapsed > 0) {
			mElapsed = 0;
		} else {
			mStartedAt = System.getTimer();
			mRunning = true;
		}
		WatchUi.requestUpdate();
	}

	// largest of the given fonts whose text still fits in maxWidth pixels
	function fitFont(dc, text, maxWidth, fonts) {
		for (var i = 0; i < fonts.size(); i++) {
			if (dc.getTextWidthInPixels(text, fonts[i]) <= maxWidth) {
				return fonts[i];
			}
		}
		return fonts[fonts.size() - 1];
	}

	function onUpdate(dc) {
		var w = dc.getWidth();
		var h = dc.getHeight();
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
		dc.clear();

		var clock = System.getClockTime();
		var hour = clock.hour;
		if (!System.getDeviceSettings().is24Hour) {
			hour = hour % 12;
			hour = (hour == 0) ? 12 : hour;
		}
		var timeText = Lang.format("$1$:$2$:$3$", [hour.format("%02d"), clock.min.format("%02d"), clock.sec.format("%02d")]);
		dc.drawText(w/2, h*0.34, fitFont(dc, timeText, w*0.78, [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD, Graphics.FONT_MEDIUM]), timeText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

		var total = mElapsed + (mRunning ? System.getTimer() - mStartedAt : 0);
		var secs = total / 1000;
		var swText = Lang.format("$1$:$2$.$3$", [(secs / 60).format("%02d"), (secs % 60).format("%02d"), ((total % 1000) / 100).format("%d")]);
		dc.setColor(mRunning ? Graphics.COLOR_GREEN : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(w/2, h*0.62, fitFont(dc, swText, w*0.6, [Graphics.FONT_NUMBER_MILD, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL]), swText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

		dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		var hint = mRunning ? "tap: stop" : (mElapsed > 0 ? "tap: reset" : "tap: start");
		dc.drawText(w/2, h*0.84, Graphics.FONT_XTINY, hint, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}
}

class ClockDelegate extends WatchUi.BehaviorDelegate {

	var mView;

	function initialize(view) {
		BehaviorDelegate.initialize();
		mView = view;
	}

	function onSelect() {
		mView.toggleStopwatch();
		return true;
	}

	function onTap(clickEvent) {
		mView.toggleStopwatch();
		return true;
	}
}
