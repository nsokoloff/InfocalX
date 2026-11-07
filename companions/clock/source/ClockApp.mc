using Toybox.Application;
using Toybox.Complications;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Lang;

// Infocal Clock: full screen clock with seconds + stopwatch.
// Publishes a complication so the Infocal watch face can launch it when you tap the hour.
class ClockApp extends Application.AppBase {

	function initialize() {
		AppBase.initialize();
	}

	function onStart(state) {
		publish();
	}

	// The watch face finds this app through its published complication, so publish on every start.
	function publish() {
		if (Toybox has :Complications) {
			var clock = System.getClockTime();
			try {
				Complications.updateComplication(0, {:value => Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")])});
			} catch (ex) {
				// not supported on this device/firmware
			}
		}
	}

	function getInitialView() {
		var view = new ClockView();
		return [view, new ClockDelegate(view)];
	}
}
