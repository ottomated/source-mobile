# Source Mobile
> An app for SPS students to access their grades

The [website for the SPS source](https://ps.seattleschools.org) is not responsive and a pain to use on a mobile device. This app, written in [Flutter](https://flutter.io), serves as a cross-platform method for reading grades much more easily.

<a href="https://ottomated.net"><img src="img/header.png" width="500"/></a>

<a href="https://play.google.com/store/apps/details?id=net.ottomated.sourcemobile"><img src="https://play.google.com/intl/en_us/badges/images/generic/en_badge_web_generic.png" alt="Get it on Google Play" width="150"/></a>

<a href="https://itunes.apple.com/us/app/source-mobile/id1441562686?mt=8"><img src="https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2018-11-11&kind=iossoftware&bubble=ios_apps" width="150"/></a>

## Development

[Install Flutter](https://flutter.io/docs/get-started/install)

```
git clone https://github.com/ottomated/source-mobile
cd source-mobile
flutter run
```

Source files are located in `lib/*.dart`.

## Release History

* 1.2
    * Several tweaks in admin panel
    * Fixed a bug where I was dependant on there being a grade in Q1 or Q3
    * Caught a few internet errors
    * Show GPAs with 2 digits of precision
    * Update dialog no longer writes a review on iOS
    * Add Grade Calculator
    * Add theme switcher
* 1.1.8
    * Catch more internet errors
* 1.1.7
    * Fixed various bugs
* 1.1.6
    * Added update checking
* 1.1.5
    * Added custom analytics and admin panel
    * Actually parsing GPAs by letter instead of percent
* 1.1.3
    * Actually parsing P grades instead of ignoring them
    * Made the bug report system better and actually working on iOS
* 1.1.1
    * Hotfixed quarter selection below, I had a one-line if that I put an extra line into accidentally
* 1.1.0
    * Added category filtering, by clicking the quarter or semester grade
    * Added a bug report system
* 1.0.4
    * Completely removed MENTORSHIP from GPA calculations
* 1.0.3
    * Fixed the same bug from 1.0.1 that I overwrote accidentally
* 1.0.2
    * Bug fixes
    * Added a test_student account
* 1.0.1
    * Fixed a minor HTML parsing bug that caused P grades to show up as 0%
* 1.0.0
    * Initial release

## Meta

Ottomated – otto@ottomated.net

Distributed under the GNU GPLv3 license. See ``LICENSE`` for more information.

## Contributing

1. Fork it (<https://github.com/ottomated/source-mobile/fork>)
2. Create your feature branch (`git checkout -b feature/NewStuff`)
3. Commit your changes (`git commit -am 'Add some NewStuff'`)
4. Push to the branch (`git push origin feature/NewStuff`)
5. Create a new Pull Request