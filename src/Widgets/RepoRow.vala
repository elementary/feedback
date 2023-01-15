/*
* Copyright 2019 elementary, Inc. (https://elementary.io)
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

public class Feedback.RepoRow : Gtk.ListBoxRow {
    public Feedback.MainWindow.Category category { get; construct; }
    public GLib.Icon? icon { get; construct; }
    public string title { get; construct; }
    public string url { get; construct; }

    public RepoRow (string title, GLib.Icon? icon, Feedback.MainWindow.Category category, string url) {
        Object (
            category: category,
            icon: icon,
            title: title,
            url: url
        );
    }

    construct {
        var label = new Gtk.Label (title) {
            hexpand = true,
            wrap = true,
            xalign = 0
        };

        var selection_icon = new Gtk.Image.from_icon_name ("object-select-symbolic", Gtk.IconSize.MENU) {
            no_show_all = true,
            visible = false
        };

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_end = 6,
            margin_bottom = 3,
            margin_start = 6
        };

        if (icon != null) {
            var icon = new Gtk.Image.from_gicon (icon, Gtk.IconSize.DND) {
                pixel_size = 32
            };

            box.add (icon);
        }
        box.add (label);
        box.add (selection_icon);

        add (box);

        state_flags_changed.connect ((flags) => {
            selection_icon.visible = Gtk.StateFlags.SELECTED in flags;
        });
    }
}
