using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Application;

// On-watch settings ("Customize"). Sections and labels are generated from settings.xml,
// see tools/gen_settings_menu.py. Text/date settings (API key, custom text, countdown date)
// can only be edited in Garmin Connect.

// Top level: one entry per section.
function buildSettingsMenu() {
	var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.AppName)});
	var data = settingsMenuData();
	for (var i = 0; i < data.size(); i++) {
		menu.addItem(new WatchUi.MenuItem(data[i][0], null, i, null));
	}
	return menu;
}

// Second level: the settings of one section, each showing its current value.
function buildSectionMenu(section) {
	var menu = new WatchUi.Menu2({:title => section[0]});
	var entries = section[1];
	for (var i = 0; i < entries.size(); i++) {
		var entry = entries[i];
		var key = entry[0];
		var current = Application.getApp().getProperty(key);
		if (entry[2] == 0) {
			menu.addItem(new WatchUi.ToggleMenuItem(entry[1], {:enabled => "On", :disabled => "Off"}, key, current == true, null));
		} else {
			menu.addItem(new WatchUi.MenuItem(entry[1], optionLabel(entry[3], current), key, null));
		}
	}
	return menu;
}

function resolveText(value) {
	if (value instanceof Lang.String) {
		return value;
	}
	return WatchUi.loadResource(value);
}

function optionLabel(options, current) {
	for (var i = 0; i < options.size(); i++) {
		if (options[i][0] == current) {
			return resolveText(options[i][1]);
		}
	}
	return "";
}

function findSettingEntry(key) {
	var data = settingsMenuData();
	for (var g = 0; g < data.size(); g++) {
		var entries = data[g][1];
		for (var i = 0; i < entries.size(); i++) {
			if (entries[i][0].equals(key)) {
				return entries[i];
			}
		}
	}
	return null;
}

function settingsChanged() {
	Application.getApp().onSettingsChanged();
}

// Handles both menu levels: section entries have a Number id, setting entries a String id.
class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

	function initialize() {
		Menu2InputDelegate.initialize();
	}

	function onSelect(item) {
		var id = item.getId();
		if (id instanceof Lang.Number) {
			var section = settingsMenuData()[id];
			WatchUi.pushView(buildSectionMenu(section), new SettingsMenuDelegate(), WatchUi.SLIDE_LEFT);
			return;
		}
		if (item instanceof WatchUi.ToggleMenuItem) {
			Application.getApp().setProperty(id, item.isEnabled());
			settingsChanged();
			return;
		}
		// list setting: open a menu with the choices
		var entry = findSettingEntry(id);
		if (entry == null) {
			return;
		}
		var options = entry[3];
		var current = Application.getApp().getProperty(id);
		var sub = new WatchUi.Menu2({:title => item.getLabel()});
		var focus = 0;
		for (var i = 0; i < options.size(); i++) {
			var selected = options[i][0] == current;
			if (selected) {
				focus = i;
			}
			sub.addItem(new WatchUi.MenuItem(resolveText(options[i][1]), selected ? "current" : null, options[i][0], null));
		}
		sub.setFocus(focus);
		WatchUi.pushView(sub, new SettingsChoiceDelegate(id, item), WatchUi.SLIDE_LEFT);
	}
}

class SettingsChoiceDelegate extends WatchUi.Menu2InputDelegate {

	var mKey;
	var mParentItem;

	function initialize(key, parentItem) {
		Menu2InputDelegate.initialize();
		mKey = key;
		mParentItem = parentItem;
	}

	function onSelect(item) {
		Application.getApp().setProperty(mKey, item.getId());
		mParentItem.setSubLabel(item.getLabel());
		settingsChanged();
		WatchUi.popView(WatchUi.SLIDE_RIGHT);
	}
}
