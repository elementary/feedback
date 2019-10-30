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

public class Feedback.TextView : Gtk.ScrolledWindow {
    public Gtk.TextView text_view { get; set; }

    public TextView () {
        expand = true;
        hadjustment = null;
        vadjustment = null;

        text_view = new Gtk.TextView ();
        text_view.hexpand = true;
        text_view.height_request = 35;
        text_view.margin = 3;
        add (text_view);
    }

}