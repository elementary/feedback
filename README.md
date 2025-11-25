# Feedback
[![Translation status](https://l10n.elementary.io/widgets/desktop/-/feedback/svg-badge.svg)](https://l10n.elementary.io/engage/desktop/?utm_source=widget)

GitHub Issue Reporter

![Feedback Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* libappstream-dev (>=1.0.0)
* libgranite-7-dev (>=7.7.0)
* libgtk-4-dev (>=4.10)
* libadwaita-1-dev (>=1.4.0)
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.feedback`

    ninja install
    io.elementary.feedback
