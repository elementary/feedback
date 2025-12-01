/*
* Copyright 2019-2020 elementary, Inc. (https://elementary.io)
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

public class Feedback.MainWindow : Gtk.ApplicationWindow {
    private Gtk.ListBox listbox;
    private Gtk.SearchEntry search_entry;
    private Category? category_filter;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            icon_name: "io.elementary.feedback",
            title: _("Feedback")
        );
    }

    construct {
        var image_icon = new Gtk.Image.from_icon_name ("io.elementary.feedback") {
            pixel_size = 48,
            valign = Gtk.Align.START
        };

        var primary_label = new Gtk.Label (_("Send feedback for which component?")) {
            hexpand = true,
            selectable = true,
            max_width_chars = 50,
            wrap = true,
            xalign = 0
        };
        primary_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var secondary_label = new Gtk.Label (_("Select an item from the list to send feedback or report a problem from your web browser.")) {
            selectable = true,
            max_width_chars = 50,
            wrap = true,
            xalign = 0
        };

        search_entry = new Gtk.SearchEntry () {
            margin_top = 24,
            placeholder_text = _("Search")
        };

        var apps_category = new CategoryRow (Category.DEFAULT_APPS);
        var panel_category = new CategoryRow (Category.PANEL);
        var settings_category = new CategoryRow (Category.SETTINGS);
        var system_category = new CategoryRow (Category.SYSTEM);

        var category_list = new Gtk.ListBox () {
            selection_mode = SINGLE
        };
        category_list.append (apps_category);
        category_list.append (panel_category);
        category_list.append (settings_category);
        category_list.append (system_category);

        var category_page = new Adw.NavigationPage (category_list, _("Categories"));

        var back_button = new Granite.BackButton (_("Categories")) {
            halign = Gtk.Align.START,
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6
        };

        var category_title = new Gtk.Label ("") {
            hexpand = true,
            justify = Gtk.Justification.CENTER,
            margin_start = 6,
            margin_end = 6,
            wrap = true
        };

        var category_header = new Gtk.CenterBox ();
        category_header.set_start_widget (back_button);
        category_header.set_center_widget (category_title);

        var spinner = new Gtk.Spinner () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        spinner.start ();

        var placeholder = new Granite.Placeholder ("") {
            description = _("Change search terms to the name of an installed app, panel indicator, system settings page, or desktop component."),
            icon = new ThemedIcon ("edit-find-symbolic")
        };

        var placeholder_stack = new Gtk.Stack ();
        placeholder_stack.add_child (placeholder);
        placeholder_stack.add_child (spinner);
        placeholder_stack.visible_child = spinner;

        listbox = new Gtk.ListBox () {
            activate_on_single_click = false,
            hexpand = true,
            vexpand = true
        };
        listbox.add_css_class ("rich-list");
        listbox.set_filter_func (filter_function);
        listbox.set_sort_func (sort_function);
        listbox.set_placeholder (placeholder_stack);

        var appstream_pool = new AppStream.Pool ();
        appstream_pool.reset_extra_data_locations ();
        appstream_pool.set_flags (
            appstream_pool.get_flags () |
            AppStream.PoolFlags.LOAD_FLATPAK |
            AppStream.PoolFlags.RESOLVE_ADDONS
        );

        appstream_pool.load_async.begin (null, (obj, res) => {
            try {
                var loaded = appstream_pool.load_async.end (res);

                foreach (var app in app_entries) {
                    var component_table = new HashTable<string, AppStream.Component> (str_hash, str_equal);

                    appstream_pool.get_components_by_id (app).as_array ().foreach ((component) => {
                        if (component_table[component.id] != null) {
                            return;
                        }

                        component_table[component.id] = component;
                        append_row_from_component (component, DEFAULT_APPS);
                    });
                }

                get_compulsory_for_desktop.begin (appstream_pool, (obj, res) => {
                    var components = get_compulsory_for_desktop.end (res);
                    components.foreach ((component) => {
                        // FIXME: This should use kind != DESKTOP_APP but some metainfo is currently inaccurate
                        if (component.kind != ADDON && !(component.id in app_entries)) {
                            append_row_from_component (component, SYSTEM);
                        }
                    });

                    placeholder_stack.visible_child = placeholder;
                });

                appstream_pool.get_components_by_extends ("io.elementary.settings").as_array ().foreach ((component) => {
                    append_row_from_component (component, SETTINGS);
                });

                appstream_pool.get_components_by_extends ("io.elementary.wingpanel").as_array ().foreach ((component) => {
                    append_row_from_component (component, PANEL);
                });
            } catch (Error e) {
                critical (e.message);
            }
        });

        var scrolled = new Gtk.ScrolledWindow () {
            child = listbox,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        var repo_list_box = new Gtk.Box (Gtk.Orientation.VERTICAL ,0);
        repo_list_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        repo_list_box.append (category_header);
        repo_list_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        repo_list_box.append (scrolled);

        var components_page = new Adw.NavigationPage (repo_list_box , _("Components"));

        var navigation_view = new Adw.NavigationView () {
            vexpand = true
        };
        navigation_view.add (category_page);

        var frame = new Gtk.Frame (null) {
            child = navigation_view,
            margin_top = 12
        };

        var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            action_name = "app.quit"
        };

        var report_button = new Gtk.Button.with_label (_("Send Feedback…")) {
            sensitive = false
        };
        report_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            halign = Gtk.Align.END,
            homogeneous = true
        };
        button_box.add_css_class ("dialog-action-area");
        button_box.append (cancel_button);
        button_box.append (report_button);

        var grid = new Gtk.Grid () {
            column_spacing = 12
        };
        grid.add_css_class ("dialog-content-area");
        grid.attach (image_icon, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (search_entry, 0, 2, 2);
        grid.attach (frame, 0, 3, 2);

        var dialog_vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        dialog_vbox.add_css_class ("dialog-vbox");
        dialog_vbox.append (grid);
        dialog_vbox.append (button_box);

        var window_handle = new Gtk.WindowHandle () {
            child = dialog_vbox
        };

        titlebar = new Gtk.Label ("") {
            visible = false
        };

        child = window_handle;
        set_default_widget (report_button);
        add_css_class ("dialog");

        search_entry.grab_focus ();

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        components_page.bind_property ("title", category_title, "label", SYNC_CREATE);

        category_list.row_activated.connect ((row) => {
            navigation_view.push (components_page);

            category_filter = ((CategoryRow) row).category;
            components_page.title = category_filter.to_string ();

            listbox.invalidate_filter ();
            var adjustment = scrolled.get_vadjustment ();
            adjustment.set_value (adjustment.lower);
        });

        back_button.clicked.connect (() => {
            category_list.select_row (null);
        });

        listbox.selected_rows_changed.connect (() => {
            var row = listbox.get_first_child ();
            while (row != null) {
                if (row is RepoRow) {
                    row.selected = ((RepoRow) row).is_selected ();
                }

                row = row.get_next_sibling ();
            }

            report_button.sensitive = listbox.get_selected_row () != null;
        });

        listbox.row_activated.connect ((row) => {
            launch_from_row ((RepoRow) row);
        });

        report_button.clicked.connect (() => {
            launch_from_row ((RepoRow) listbox.get_selected_row ());
        });

        search_entry.search_changed.connect (() => {
            if (search_entry.text != "") {
                placeholder.title = _("No results found for “%s”").printf (search_entry.text);
                components_page.title = _("Search Results");

                if (navigation_view.visible_page != components_page) {
                    navigation_view.push (components_page);
                }
            } else if (category_list.get_selected_row () == null) {
                navigation_view.pop ();
            } else if (category_filter != null) {
                components_page.title = category_filter.to_string ();
            }

            listbox.invalidate_filter ();
        });

        navigation_view.popped.connect (() => {
            listbox.select_row (null);
            search_entry.text = "";
        });
    }

    private void append_row_from_component (AppStream.Component component, Feedback.MainWindow.Category category) {
        var url = component.get_url (AppStream.UrlKind.BUGTRACKER);
        if (url == null) {
            // Ignore components without a bugtracker URL because rows that just show
            // a component name and can't take users to report issues are useless
            warning ("BUGTRACKER URL is not set in the component '%s'", component.name);
            return;
        }

        var repo_row = new RepoRow (
            component.name,
            icon_from_appstream_component (component),
            category,
            url
        );

        listbox.append (repo_row);
    }

    private void launch_from_row (RepoRow row) {
        var uri_launcher = new Gtk.UriLauncher (row.url);
        uri_launcher.launch.begin (null, null, (obj, res) => {
            try {
                uri_launcher.launch.end (res);
            } catch (Error err) {
                warning ("Failed to launch \"%s\": %s", row.url, err.message);
            }

            close ();
        });
    }

    private async GenericArray<AppStream.Component> get_compulsory_for_desktop (AppStream.Pool appstream_pool) {
        SourceFunc callback = get_compulsory_for_desktop.callback;

        var components = new GenericArray<AppStream.Component> ();
        new Thread<void> ("get_compulsory_for_desktop", () => {
            appstream_pool.get_components ().as_array ().foreach ((component) => {
                component.get_compulsory_for_desktops ().foreach ((desktop) => {
                    if (desktop == Environment.get_variable ("XDG_CURRENT_DESKTOP")) {
                        components.add (component);
                    }
                });
            });

            Idle.add ((owned) callback);
        });

        yield;
        return components;
    }

    private Icon icon_from_appstream_component (AppStream.Component component) {
        var as_icons = component.get_icons ();
        Icon icon;

        if (as_icons.length == 0) {
            // the appdata has no icons, fallback to id
            icon = new ThemedIcon (component.id);
        } else {
            var name = as_icons[0].get_name ();

            if (as_icons[0].get_kind () == AppStream.IconKind.STOCK) {
                icon = new ThemedIcon (name);
            } else {
                var underscore_index = name.index_of ("_");
                underscore_index.clamp (0, name.length);

                icon = new ThemedIcon (name.substring (
                    // some icon names are prepended with the package name
                    underscore_index + 1,
                    // non-stock type icons has the extension in the name.
                    name.last_index_of (".") - underscore_index - 1
                ));
            }
        }

        if (!Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).has_gicon (icon)) {
            icon = new ThemedIcon ("application-default-icon");
        }

        return icon;
    }

    [CCode (instance_pos = -1)]
    private bool filter_function (Gtk.ListBoxRow row) {
        if (search_entry.text != "") {
            return search_entry.text.down () in ((RepoRow) row).title.down ();
        } else if (((RepoRow) row).category == category_filter) {
            return true;
        }
        return false;
    }

    [CCode (instance_pos = -1)]
    private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        return ((RepoRow) row1).title.collate (((RepoRow) row2).title);
    }

    static string[] app_entries = {
         "io.elementary.appcenter",
         "io.elementary.calculator",
         "io.elementary.calendar",
         "io.elementary.camera",
         "io.elementary.code",
         "io.elementary.feedback",
         "org.gnome.Evince",
         "org.gnome.Epiphany",
         "org.gnome.font-viewer.desktop",
         "io.elementary.files",
         "io.elementary.mail",
         "io.elementary.maps",
         "io.elementary.monitor",
         "io.elementary.music",
         "io.elementary.photos",
         "io.elementary.screenshot",
         "io.elementary.settings",
         "io.elementary.shortcut-overlay",
         "io.elementary.tasks",
         "io.elementary.terminal",
         "io.elementary.videos"
    };

    public enum Category {
        DEFAULT_APPS,
        PANEL,
        SETTINGS,
        SYSTEM;

        public string to_string () {
            switch (this) {
                case PANEL:
                    return _("Panel Indicators");
                case SETTINGS:
                    return _("System Settings");
                case SYSTEM:
                    return _("Desktop Components");
                default:
                    return _("Default Apps");
            }
        }
    }
}
