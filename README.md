# Feedback
GitHub Issue Reporter

![Feedback Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* libgranite-dev (>=5)
* libgtk-3-dev
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.feedback`

    ninja install
    io.elementary.feedback
