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
    private uint configure_id;
    private Gtk.ListBox listbox;
    private Category? category_filter;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            icon_name: "io.elementary.feedback",
            title: _("Feedback")
        );
    }

    class construct {
        set_css_name ("dialog");
    }

    construct {
        var titlebar = new Gtk.HeaderBar ();
        titlebar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        titlebar.set_custom_title (new Gtk.Grid ());

        var image_icon = new Gtk.Image.from_icon_name ("io.elementary.feedback", Gtk.IconSize.DIALOG);

        var primary_label = new Gtk.Label (_("Send feedback for which component?")) {
            selectable = true,
            max_width_chars = 50,
            wrap = true,
            xalign = 0
        };
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var secondary_label = new Gtk.Label (_("Select an item from the list to send feedback or report a problem from your web browser.")) {
            selectable = true,
            max_width_chars = 50,
            wrap = true,
            xalign = 0
        };

        var apps_category = new CategoryRow (Category.DEFAULT_APPS);
        var panel_category = new CategoryRow (Category.PANEL);
        var settings_category = new CategoryRow (Category.SETTINGS);
        var system_category = new CategoryRow (Category.SYSTEM);

        var category_list = new Gtk.ListBox () {
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.NONE
        };
        category_list.add (apps_category);
        category_list.add (panel_category);
        category_list.add (settings_category);
        category_list.add (system_category);

        var back_button = new Gtk.Button.with_label (_("Categories")) {
            halign = Gtk.Align.START,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var category_title = new Gtk.Label ("");

        var category_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        category_header.pack_start (back_button);
        category_header.set_center_widget (category_title);

        var spinner = new Gtk.Spinner () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        spinner.start ();
        spinner.show ();

        listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        listbox.set_filter_func (filter_function);
        listbox.set_sort_func (sort_function);
        listbox.set_placeholder (spinner);

        var appstream_pool = new AppStream.Pool ();
#if HAS_APPSTREAM_0_15
        appstream_pool.reset_extra_data_locations ();
        appstream_pool.set_flags (
            appstream_pool.get_flags () |
            AppStream.PoolFlags.LOAD_FLATPAK |
            AppStream.PoolFlags.RESOLVE_ADDONS
        );
#else
        appstream_pool.clear_metadata_locations ();
        // flatpak's appstream files exists only inside they sandbox
        unowned var appdata_dir = "/var/lib/flatpak/app/%s/current/active/files/share/appdata";
        foreach (var app in app_entries) {
            appstream_pool.add_metadata_location (appdata_dir.printf (app));
        }
#endif

        appstream_pool.load_async.begin (null, (obj, res) => {
            try {
                var loaded = appstream_pool.load_async.end (res);

                foreach (var app in app_entries) {
                    var component_table = new HashTable<string, AppStream.Component> (str_hash, str_equal);

                    appstream_pool.get_components_by_id (app).foreach ((component) => {
                        if (component_table[component.id] == null) {
                            component_table[component.id] = component;

                            var repo_row = new RepoRow (
                                component.name,
                                icon_from_appstream_component (component),
                                Category.DEFAULT_APPS,
                                component.get_url (AppStream.UrlKind.BUGTRACKER)
                            );

                            listbox.add (repo_row);
                        }
                    });
                }

                // FIXME: Dock should ship appdata
                var dock_row = new RepoRow (
                    _("Dock"),
                    new ThemedIcon ("application-default-icon"),
                    Category.SYSTEM,
                    "https://github.com/elementary/dock/issues/new/choose"
                );
                listbox.add (dock_row);

                get_compulsory_for_desktop.begin (appstream_pool, (obj, res) => {
                    var components = get_compulsory_for_desktop.end (res);
                    components.foreach ((component) => {
                        var repo_row = new RepoRow (
                            component.name,
                            icon_from_appstream_component (component),
                            Category.SYSTEM,
                            component.get_url (AppStream.UrlKind.BUGTRACKER)
                        );

                        listbox.add (repo_row);
                    });

                    listbox.show_all ();
                });

                appstream_pool.get_components_by_id ("io.elementary.switchboard").foreach ((component) => {
                    component.get_addons ().foreach ((addon) => {
                        var repo_row = new RepoRow (
                            addon.name,
                            get_extension_icon_from_appstream (addon.get_icons ()),
                            Category.SETTINGS,
                            addon.get_url (AppStream.UrlKind.BUGTRACKER)
                        );

                        listbox.add (repo_row);
                    });
                });

                appstream_pool.get_components_by_id ("io.elementary.wingpanel").foreach ((component) => {
                    component.get_addons ().foreach ((addon) => {
                        var repo_row = new RepoRow (
                            addon.name,
                            get_extension_icon_from_appstream (addon.get_icons ()),
                            Category.PANEL,
                            addon.get_url (AppStream.UrlKind.BUGTRACKER)
                        );

                        listbox.add (repo_row);
                    });
                });
            } catch (Error e) {
                critical (e.message);
            }
        });

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (listbox);

        var repo_list_box = new Gtk.Box (Gtk.Orientation.VERTICAL ,0);
        repo_list_box.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        repo_list_box.add (category_header);
        repo_list_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        repo_list_box.add (scrolled);

        var deck = new Hdy.Deck () {
            can_swipe_back = true
        };
        deck.add (category_list);
        deck.add (repo_list_box);

        var frame = new Gtk.Frame (null) {
            margin_top = 24,
            margin_bottom = 24
        };
        frame.add (deck);

        var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            action_name = "app.quit"
        };

        var report_button = new Gtk.Button.with_label (_("Send Feedback…")) {
            sensitive = false
        };
        report_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            halign = Gtk.Align.END,
            homogeneous = true
        };
        button_box.add (cancel_button);
        button_box.add (report_button);

        var grid = new Gtk.Grid () {
            column_spacing = 12
        };
        grid.attach (image_icon, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (frame, 1, 2);

        var dialog_vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin = 12,
            margin_top = 0
        };
        dialog_vbox.add (grid);
        dialog_vbox.add (button_box);

        add (dialog_vbox);
        set_titlebar (titlebar);

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        category_list.row_activated.connect ((row) => {
            deck.visible_child = repo_list_box;
            category_filter = ((CategoryRow) row).category;
            category_title.label = ((CategoryRow) row).category.to_string ();
            listbox.invalidate_filter ();
            var adjustment = scrolled.get_vadjustment ();
            adjustment.set_value (adjustment.lower);
        });

        back_button.clicked.connect (() => {
            deck.navigate (Hdy.NavigationDirection.BACK);
            report_button.sensitive = false;
        });

        listbox.selected_rows_changed.connect (() => {
            foreach (var repo_row in listbox.get_children ()) {
                ((RepoRow) repo_row).selected = false;
            }
            ((RepoRow) listbox.get_selected_row ()).selected = true;
            report_button.sensitive = true;
        });

        report_button.clicked.connect (() => {
            try {
                var url = ((RepoRow) listbox.get_selected_row ()).url;
                Gtk.show_uri_on_window (null, url, Gtk.get_current_event_time ());
            } catch (Error e) {
                critical (e.message);
            }
            destroy ();
        });
    }

    private async GenericArray<AppStream.Component> get_compulsory_for_desktop (AppStream.Pool appstream_pool) {
        SourceFunc callback = get_compulsory_for_desktop.callback;

        var components = new GenericArray<AppStream.Component> ();
        new Thread<void> ("get_compulsory_for_desktop", () => {
            appstream_pool.get_components ().foreach ((component) => {
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

    private Icon get_extension_icon_from_appstream (GLib.GenericArray<AppStream.Icon> appstream_icons) {
        foreach (unowned AppStream.Icon appstream_icon in appstream_icons) {
            if (appstream_icon.get_kind () == AppStream.IconKind.STOCK) {
                return new ThemedIcon (appstream_icon.get_name ());
            }
        }

        return new ThemedIcon ("extension");
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

        return icon;
    }

    [CCode (instance_pos = -1)]
    private bool filter_function (Gtk.ListBoxRow row) {
        if (((RepoRow) row).category == category_filter) {
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
         "org.gnome.Evince",
         "org.gnome.Epiphany",
         "io.elementary.files",
         "io.elementary.mail",
         "io.elementary.music",
         "io.elementary.photos",
         "io.elementary.screenshot",
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

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;

            if (is_maximized) {
                Feedback.Application.settings.set_boolean ("window-maximized", true);
            } else {
                Feedback.Application.settings.set_boolean ("window-maximized", false);

                Gdk.Rectangle rect;
                get_allocation (out rect);
                Feedback.Application.settings.set ("window-size", "(ii)", rect.width, rect.height);

                int root_x, root_y;
                get_position (out root_x, out root_y);
                Feedback.Application.settings.set ("window-position", "(ii)", root_x, root_y);
            }

            return false;
        });

        return base.configure_event (event);
    }
}
