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

    private static Gtk.CssProvider css_provider;
    private const string css = """
        row image {
            background-color: @theme_selected_bg_color;
            color: @theme_selected_fg_color;
            border-radius: calc(8rem / 9);
            -gtk-icon-size: calc(12rem / 9);
            margin: 0 calc(3rem / 9);
            min-height: calc(16rem / 9);
            min-width: calc(16rem / 9);
            opacity: 0;
        }

        row:selected image {
            opacity: 1;
        }

        row:selected image:backdrop {
            background-color: @theme_unfocused_selected_bg_color;
            color: @theme_unfocused_selected_fg_color;
        }
    """;

    public RepoRow (string title, GLib.Icon? icon, Feedback.MainWindow.Category category, string url) {
        Object (
            category: category,
            icon: icon,
            title: title,
            url: url
        );
    }

    static construct {
        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_data (css.data);
    }

    construct {
        var label = new Gtk.Label (title) {
            hexpand = true,
            xalign = 0
        };

        var selection_icon = new Gtk.Image.from_icon_name ("object-select-symbolic") {
            valign = Gtk.Align.CENTER
        };
        selection_icon.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

        if (icon != null) {
            var icon = new Gtk.Image.from_gicon (icon) {
                icon_size = Gtk.IconSize.LARGE
            };
            box.append (icon);
        }
        box.append (label);
        box.append (selection_icon);

        child = box;
    }
}
