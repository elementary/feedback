/*
* Copyright 2019-2022 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

public class Feedback.Application : Gtk.Application {
    public static GLib.Settings settings;

    public Application () {
        Object (
            application_id: "io.elementary.feedback",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    static construct {
        settings = new Settings ("io.elementary.feedback");
        GLib.Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain (GETTEXT_PACKAGE);
    }

    protected override void startup () {
        base.startup ();

        Granite.init ();

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q"});

        quit_action.activate.connect (quit);
    }

    protected override void activate () {
        if (active_window == null) {
            var main_window = new MainWindow (this);

            /*
            * This is very finicky.
            * Set maximize after height/width else window is min size on unmaximize
            * Bind maximize as SET else get get bad sizes
            */
            settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
            settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

            if (settings.get_boolean ("window-maximized")) {
                main_window.maximize ();
            }

            settings.bind ("window-maximized", main_window, "maximized", SettingsBindFlags.SET);
        }

        active_window.present ();
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
