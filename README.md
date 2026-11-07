# InfocalX

InfocalX is a fork of [Infocal](https://github.com/RyanDam/Infocal), a watchface for Garmin devices, by Dam Vu Duy.
It adds support for the fenix 7 Pro, tap-to-open fields, an on-watch Customize menu, and a Linux build.

The original app is on the [Garmin Connect IQ store](https://apps.garmin.com/en-US/apps/c97c4e34-55e4-4601-b5c2-45763bc481a2#0).
This fork is not published on the store, you build and sideload it yourself (see [Building on Linux](#building-on-linux)).

# What is different in this fork

- **fenix 7 Pro support.**
  Added `fenix7pro` and `fenix7pronowifi`.
  Tested on a fenix 7 Pro Solar (part number 006-B4375-00).
- **Builds with the current Connect IQ SDK.**
  The 2020 code was fixed so the current compiler accepts it.
- **Tap a field to open the app behind it.**
  See [Tap to open](#tap-to-open).
- **Customize on the watch.**
  Change the main settings on the watch itself, without the phone.
  See [Customize on the watch](#customize-on-the-watch).
- **Infocal Clock companion app.**
  Tap the big hour to open a clock with seconds and a stopwatch.
  See [Infocal Clock](#infocal-clock).
- **Active calories only.**
  The calories field shows active calories, not total burned calories.
- **Battery in days uses the watch's own estimate.**
  The old homemade consumption estimate was removed.
- **Linux build script.**
  `build-linux.sh` builds with the SDK and can copy the result to a mounted watch.

# Description

Infocal is a digital and analogue watchface, carefully made with high quality rendering.
It's both customizable and functional.
With up to 8 complications on the screen, each complication can show a variety of data:

- Date
- Digital time/2nd timezone
- Battery (percent or days left)
- Active calories
- Live heart rate
- Moved distance (day/weekly)
- Move bar
- Daily steps
- Active minutes
- Notification/Alarm/Connection status
- Altitude
- Temperature (on-device sensor)
- Temperature (outside)
- Temperature (high/low)
- Sunrise/Sunset time
- Floor climbed
- Barometer data
- Countdown to event day
- Weather condition
- Wind

# Tap to open

Touching a field on the watchface opens the app or screen that Garmin associates with that data.
This uses the Connect IQ Complications API (`Complications.exitTo`), the same way Garmin's own watchfaces do it.

| Where you tap | What opens |
| --- | --- |
| Heart rate field | Heart rate |
| Calories field | Calories |
| Steps, distance, move bar | Steps |
| Active minutes | Intensity minutes |
| Date, time fields | Date and calendar |
| Notifications fields, small time number at the top right | Notifications |
| Date text at the top right | Calendar |
| Altitude, temperature, pressure, sunrise/sunset, floors | The matching screen |
| Weather, wind, outside temperature | Weather |
| Big hour in the middle | Infocal Clock, or the calendar if it is not installed |

Notes:

- The arc fields (12, 2, 4, 6, 8 and 10 o'clock) open whatever you assigned to that position in the settings.
- The top and bottom bars open what is assigned to them. If a bar is empty, the graph shown there opens instead.
- Some data types have no matching screen on the watch, so tapping them does nothing.
  The battery field is one of them on the fenix 7 Pro, where the battery complication has no screen.
- Tap handling needs the `ComplicationSubscriber` permission, which is declared in `manifest.xml`.

# Customize on the watch

Open the watchface settings on the watch (Customize) to change the main options without the phone.
The menu has four sections:

- **Look:** theme, analog face, digital size, big number (hour or minute), leading zero, number stripes, ticks, info on left.
- **Data fields:** the six arc positions (Top, Top right, Bottom right, Bottom, Bottom left, Top left), top and bottom bar, top and bottom graph.
- **Power & always-on:** low refresh, always-on seconds, always-on heart rate, always-on size.
- **Units & formats:** date format, English date, battery format, pressure unit, second time zone, full numbers.

Settings that need typing (OpenWeatherMap API key, custom text, countdown date) can only be edited in Garmin Connect.
The menu is generated from `resources/settings/settings.xml`.
After you change that file, regenerate it from the repo root:

```
python3 tools/gen_settings_menu.py
```

The section names and short labels live in `tools/gen_settings_menu.py`.

# Infocal Clock

`companions/clock` is a small watch app.
It shows a full screen clock with seconds and a stopwatch (tap or Start: start, stop, reset).
It publishes a Connect IQ complication so that Infocal can find and launch it when you tap the big hour.

To use it:

1. Build and install `InfocalClock` like the watchface (see below).
2. Open **Infocal Clock** once from the watch's app list.
   It registers itself when it first runs, so Infocal cannot find it before that.

# Building on Linux

You need:

- The Connect IQ SDK, with the device files for your watch.
  Install them with Garmin's [SDK Manager](https://developer.garmin.com/connect-iq/sdk/).
  The SDK Manager needs a Garmin login, and downloading a device downloads its whole API-level group.
- Java.

```
./build-linux.sh                    # builds bin/Infocal-fenix7pro.prg
./build-linux.sh fenix7pronowifi    # another device
```

The script reads the active SDK from `~/.Garmin/ConnectIQ/current-sdk.cfg`, or from `CIQ_SDK`.
It creates a developer key at `~/.Garmin/developer_key.der` if you do not have one.
Keep that key, you need the same one for future updates.
The script calls `monkeybrains.jar` directly, so it also works where `/bin/bash` does not exist (for example NixOS).
It builds with type checking turned off (`-l 0`), because this old code base was never written for the type checker.

To build the companion app:

```
APP_DIR=companions/clock APP_NAME=InfocalClock ./build-linux.sh
```

# Installing on the watch

1. Plug the watch in over USB.
   The watch first shows up in a non-storage mode and switches to the file-transfer mode after about 25 seconds.
   Wait for it, replugging resets the timer.
2. Copy the `.prg` file into `GARMIN/Apps/` on the watch.
   With the file manager of your desktop, or with `gio copy bin/Infocal-fenix7pro.prg "mtp://<device>/Internal Storage/GARMIN/Apps/Infocal.prg"`.
   You can pass a mount point as the second argument of `build-linux.sh` instead.
3. Unplug the watch.
   The watch installs the file when it is disconnected.
4. Select Infocal as the watch face.

If the app shows an IQ logo with an exclamation mark, it crashed.
The reason is written to `GARMIN/Apps/LOGS/CIQ_LOG.YML` on the watch.

# Contribution

## Code contribution
1. Fork the project
2. Develop your feature
3. Make a pull request to this project

# Settings

Please configure your watch face via Garmin Connect Mobile or Garmin Express, or on the watch itself (see above).
Here is how to do it with Garmin Connect Mobile:

https://forums.garmin.com/developer/connect-iq/w/wiki/14/changing-your-app-settings-in-garmin-express-gcm-ciq-mobile-store

# FAQs

- Why Infocal need user profile permission?

Infocal needs your profile to calculate active calories, distance goal (based on your steps and stride length), moving distance for a whole week.
Infocal is using your profile for that purposes and will not save it anywhere.

- Why Infocal need internet/background communication permission?

Infocal uses OpenWeatherMap API to fetch weather information, and only for that.

- Battery in days shows a different number than other watchfaces?

With "Battery shows: Days left", the field shows the remaining life as reported by the watch (`SystemStats.batteryInDays`).
Garmin's own value is computed internally, so it can differ from what other watchfaces or screens show.
Switch back to "Percent" if the number does not match what you expect.

- Too much data on the screen?

You can set it to "Empty" complication, it won't draw anything.

- This watchface consumes too much energy?

There's a built-in power saving mode in the settings which will reduce the screen refresh rate to once per minute.

- How to see if the watch is connected to the phone?

By using the group notification complication, if a phone is connected it will show "C" (connected), otherwise is "D" (disconnected).

- If I update the watchface via Garmin connect, all the settings reset to default?

This is a bug of Garmin Connect iOS app, please update Garmin Connect to the latest version.

- Can't get sunrise/sunset to work?

Sunrise/sunset only works if the watch has a GPS signal, try to start any activity and wait for GPS signal, then return to watch face and then everything is good.

- Complication data just show "--" value?

Not all complications are supported for any device, it depends on your device whether it is supported or not.

- A square appeared instead of a character?

Currently, this watch face only supports English (or Latin characters).

- Why weather/outside temperature is not shown/update?

Weather/outside temperature needs internet and GPS information to work.
Please set your GPS up (as instructed in the FAQs), and make sure your watch is connected to your phone (via Garmin Connect) with internet connected.

- What is the source of weather information?

This watchface get weather info from OpenWeatherMap API.

- Why weather does not update properly or showing the wrong number?

Infocal uses OpenWeatherMap API free tier, which is only allowed for 60 API calls per second or 1000 request per day.
With many people using Infocal, it exceeds the limit.
To make weather work better for you, please read API document from OpenWeatherMap here to get your own API key: https://openweathermap.org/guide#how
Your API key will need several hours to be activated by OpenWeatherMap.

- What is OpenWeatherMap API key?

It's a key to allow you to get weather information from OpenWeatherMap, as describe in "Why weather does not update properly or showing the wrong number?".

**Currently this watch face only support English (or Latin characters).**

# Credits

- InfocalX is a fork of [Infocal](https://github.com/RyanDam/Infocal) by Dam Vu Duy, released under the MIT License (see `LICENSE`).
  If you want to support the original author: [PayPal](https://www.paypal.me/pyryandam).
- Special thanks to **[warmsound](https://github.com/warmsound)** for awesome [Crystal Watchface](https://github.com/warmsound/crystal-face). Without Crystal, I'm not able to add some features (suntime, sensor history, weather...) to this watchface.
- Special thanks to **[sunpazed](https://github.com/sunpazed)** for his awesome GitHub projects. I learned a lot from him for anti-aliasing and get inspired to create curved text, which makes Infocal today.
