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
    public bool selected { get; set; }
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
        var label = new Gtk.Label (title);
        label.hexpand = true;
        label.xalign = 0;

        var selection_icon = new Gtk.Image.from_icon_name ("object-select-symbolic", Gtk.IconSize.MENU);
        selection_icon.no_show_all = true;
        selection_icon.visible = false;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin = 3;
        grid.margin_start = grid.margin_end = 6;

        if (icon != null) {
            var icon = new Gtk.Image.from_gicon (icon, Gtk.IconSize.LARGE_TOOLBAR);
            icon.pixel_size = 24;
            grid.add (icon);
        }
        grid.add (label);
        grid.add (selection_icon);

        add (grid);

        notify["selected"].connect (() => {
            selection_icon.visible = selected;
        });
    }
}
