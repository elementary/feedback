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

public class Feedback.IssueReporter : Gtk.Dialog {
    private Feedback.TextView bug_description_text_view;
    private Feedback.TextView reproduction_text_view;
    private Feedback.TextView expected_behavior_text_view;
    private Feedback.TextView logs_text_view;
    public string url { get; construct; }

    public IssueReporter (Gtk.Window parent, string url) {
        Object (
            transient_for: parent,
            url: url
        );
    }

    construct {
        var issue_type_label = new Granite.HeaderLabel (_("Issue Type"));

        var issue_type_combobox = new Gtk.ComboBoxText ();
        issue_type_combobox.append_text (_("Bug"));
        issue_type_combobox.append_text (_("Feature Request"));
        issue_type_combobox.set_active (0);

        var issue_title_label = new Granite.HeaderLabel (_("Title"));

        var issue_title_entry = new Gtk.Entry ();
        issue_title_entry.hexpand = true;

        var bug_description_label = new Granite.HeaderLabel (_("Describe the bug"));

        bug_description_text_view = new Feedback.TextView ();

        var reproduction_label = new Granite.HeaderLabel (_("To Reproduce"));

        reproduction_text_view = new Feedback.TextView ();

        var expected_behavior_label = new Granite.HeaderLabel (_("Expected Behavior"));

        expected_behavior_text_view = new Feedback.TextView ();

        var logs_label = new Granite.HeaderLabel (_("Logs"));

        logs_text_view = new Feedback.TextView ();

        var basic_info_check_button = new Gtk.CheckButton.with_label ("Basic Application and OS Information");
        basic_info_check_button.margin_top = 4;

        var form_grid = new Gtk.Grid ();
        form_grid.margin_start = form_grid.margin_end = 12;
        form_grid.orientation = Gtk.Orientation.VERTICAL;
        form_grid.row_spacing = 3;
        form_grid.valign = Gtk.Align.CENTER;
        form_grid.vexpand = true;
        form_grid.add (issue_type_label);
        form_grid.add (issue_type_combobox);
        form_grid.add (issue_title_label);
        form_grid.add (issue_title_entry);
        form_grid.add (bug_description_label);
        form_grid.attach_next_to (bug_description_text_view, bug_description_label, Gtk.PositionType.BOTTOM, 1, 35);
        form_grid.add (reproduction_label);
        form_grid.attach_next_to (reproduction_text_view, reproduction_label, Gtk.PositionType.BOTTOM, 1, 35);
        form_grid.add (expected_behavior_label);
        form_grid.attach_next_to (expected_behavior_text_view, expected_behavior_label, Gtk.PositionType.BOTTOM, 1, 35);
        form_grid.add (logs_label);
        form_grid.attach_next_to (logs_text_view, logs_label, Gtk.PositionType.BOTTOM, 1, 35);
        form_grid.add (basic_info_check_button);
        form_grid.show_all ();

        deletable = false;
        modal = true;
        resizable= false;
        width_request = 760;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        get_content_area ().add (form_grid);

        var cancel_button = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        cancel_button.margin_bottom = cancel_button.margin_end = 6;
        cancel_button.margin_top = 14;

        var create_button = add_button (_("Preview on GitHub"), Gtk.ResponseType.OK);
        create_button.margin_bottom = create_button.margin_end = 6;
        create_button.margin_top = 14;
        create_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.OK) {
                debug (serialize ());
                try {
                    url += "?title=" + issue_title_entry.text + "&body=" + serialize ();
                    AppInfo.launch_default_for_uri ("%s".printf (url), null);
                } catch (Error e) {
                    critical (e.message);
                }
            } else {
                destroy ();
            }
        });
    }

    private string serialize() {
        return Uri.escape_string (
               "## Describe the bug \n"
            +  bug_description_text_view.text_view.buffer.text
            + "\n" + "## To Reporoduce \n"
            +  reproduction_text_view.text_view.buffer.text
            + "\n" + "## Expected behavior \n"
            +  expected_behavior_text_view.text_view.buffer.text
            + "\n" + "## Logs \n"
            + "```"
            + logs_text_view.text_view.buffer.text
            + "```"
            + "\n"
            + "<details>"
            + "<summary>## Platform Information</summary>"
            + "<table>"
            + "<tr><th>Item</th><th>Value</th><tr>"
            + "<tr><td>OS</td><td>Elementary OS Juno</td><tr>"
            + "<tr><td>Kernel</td><td>5.3.7-050307-generic</td><tr>"
            + "<tr><td>Arch</td><td>x86_64</td><tr>"
            + "<tr><td>CPU</td><td>AMD Ryzen 9 3900X 12-Core Processor (24 x 4316)</td><tr>"
            + "<tr><td>GPU</td><td>AMD Navi 5700X</td><tr>"
            + "</table>"
            + "</details>"
        );
    }


}