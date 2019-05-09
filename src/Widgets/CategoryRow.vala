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

public class Feedback.CategoryRow : Gtk.ListBoxRow {
    public Feedback.MainWindow.Category category { get; construct; }

    public CategoryRow (Feedback.MainWindow.Category category) {
        Object (category: category);
    }

    construct {
        var label = new Gtk.Label (category.to_string ());
        label.hexpand = true;
        label.xalign = 0;

        var caret = new Gtk.Image.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);

        var grid = new Gtk.Grid ();
        grid.margin = 3;
        grid.margin_start = grid.margin_end = 6;
        grid.add (label);
        grid.add (caret);

        add (grid);
    }
}
