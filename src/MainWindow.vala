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
            pixel_size = 48
        };

        var primary_label = new Gtk.Label (_("Send feedback for which component?")) {
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

        var apps_category = new CategoryRow (Category.DEFAULT_APPS);
        var panel_category = new CategoryRow (Category.PANEL);
        var settings_category = new CategoryRow (Category.SETTINGS);
        var system_category = new CategoryRow (Category.SYSTEM);

        var category_list = new Gtk.ListBox ();
        category_list.activate_on_single_click = true;
        category_list.selection_mode = Gtk.SelectionMode.NONE;
        category_list.append (apps_category);
        category_list.append (panel_category);
        category_list.append (settings_category);
        category_list.append (system_category);

        var back_button = new Gtk.Button.with_label (_("Categories")) {
            halign = Gtk.Align.START,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        back_button.add_css_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var category_title = new Gtk.Label ("");

        var category_header = new Gtk.CenterBox ();
        category_header.set_start_widget (back_button);
        category_header.set_center_widget (category_title);

        listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        listbox.add_css_class ("rich-list");
        listbox.set_filter_func (filter_function);
        listbox.set_sort_func (sort_function);

        var appstream_pool = new AppStream.Pool ();
#if HAS_APPSTREAM_0_15
        appstream_pool.reset_extra_data_locations ();
#else
        appstream_pool.clear_metadata_locations ();
#endif
        try {
            if (Application.sandboxed) {
#if HAS_APPSTREAM_0_15
                appstream_pool.add_extra_data_location ("/run/host/usr/share/metainfo/", AppStream.FormatStyle.METAINFO);
#else
                appstream_pool.add_metadata_location ("/run/host/usr/share/metainfo/");
#endif
            }

            // flatpak's appstream files exists only inside they sandbox
            unowned var appdata_dir = "/var/lib/flatpak/app/%s/current/active/files/share/appdata";
            foreach (var app in app_entries) {
#if HAS_APPSTREAM_0_15
                appstream_pool.add_extra_data_location (appdata_dir.printf (app), AppStream.FormatStyle.METAINFO);
#else
                appstream_pool.add_metadata_location (appdata_dir.printf (app));
#endif
            }

            appstream_pool.load ();
        } catch (Error e) {
            critical (e.message);
        } finally {
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

                        listbox.append (repo_row);
                    }
                });
            }

            foreach (var entry in system_entries) {
                var repo_row = new RepoRow (entry.name, null, Category.SYSTEM, entry.issues_url);
                listbox.append (repo_row);
            }

            foreach (var entry in switchboard_entries) {
                appstream_pool.get_components_by_id (entry.id).foreach ((component) => {
                    var repo_row = new RepoRow (
                        component.name,
                        new ThemedIcon (entry.icon),
                        Category.SETTINGS,
                        component.get_url (AppStream.UrlKind.BUGTRACKER)
                    );

                    listbox.append (repo_row);
                });
            }

            foreach (var entry in wingpanel_entries) {
                appstream_pool.get_components_by_id (entry.id).foreach ((component) => {
                    var repo_row = new RepoRow (
                        component.name,
                        new ThemedIcon (entry.icon),
                        Category.PANEL,
                        component.get_url (AppStream.UrlKind.BUGTRACKER)
                    );

                    listbox.append (repo_row);
                });
            }
        }

        var scrolled = new Gtk.ScrolledWindow () {
            child = listbox
        };

        var repo_list_box = new Gtk.Box (Gtk.Orientation.VERTICAL ,0);
        repo_list_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        repo_list_box.append (category_header);
        repo_list_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        repo_list_box.append (scrolled);

        var leaflet = new Adw.Leaflet () {
            can_navigate_back = true,
            can_unfold = false,
            hexpand = true,
            vexpand = true
        };
        leaflet.append (category_list);
        leaflet.append (repo_list_box);

        var frame = new Gtk.Frame (null) {
            child = leaflet
        };
        frame.margin_top = 24;

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.action_name = "app.quit";

        var report_button = new Gtk.Button.with_label (_("Send Feedback…"));
        report_button.sensitive = false;
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
        grid.attach (frame, 1, 2);

        var dialog_vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        dialog_vbox.add_css_class ("dialog-vbox");
        dialog_vbox.append (grid);
        dialog_vbox.append (button_box);

        var window_handle = new Gtk.WindowHandle () {
            child = dialog_vbox
        };

        var fake_title = new Gtk.Label ("") {
            visible = false
        };

        child = window_handle;
        set_titlebar (fake_title);
        add_css_class ("dialog");

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        category_list.row_activated.connect ((row) => {
            leaflet.visible_child = repo_list_box;
            category_filter = ((CategoryRow) row).category;
            category_title.label = ((CategoryRow) row).category.to_string ();
            listbox.invalidate_filter ();
            var adjustment = scrolled.get_vadjustment ();
            adjustment.set_value (adjustment.lower);
        });

        back_button.clicked.connect (() => {
            leaflet.navigate (Adw.NavigationDirection.BACK);
            report_button.sensitive = false;
        });

        listbox.selected_rows_changed.connect (() => {
            var row = (RepoRow) listbox.get_first_child ();
            while (row != null) {
                row.selected = row.is_selected ();
                row = (RepoRow) row.get_next_sibling ();
            }

            report_button.sensitive = true;
        });

        report_button.clicked.connect (() => {
            try {
                var url = ((RepoRow) listbox.get_selected_row ()).url;
                Gtk.show_uri (null, url, Gdk.CURRENT_TIME);
            } catch (Error e) {
                critical (e.message);
            }
            destroy ();
        });
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
                // non-stock type icons has the extension in the name.
                icon = new ThemedIcon (name.substring (0, name.last_index_of (".")));
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

    private struct SystemEntry {
        string name;
        string issues_url;
    }

    static SystemEntry[] system_entries = {
        SystemEntry () {
            name = _("Applications Menu"),
            issues_url = "https://github.com/elementary/applications-menu/issues/new/choose"
        },
        SystemEntry () {
            name = _("Captive Network Assistant"),
            issues_url = "https://github.com/elementary/capnet-assist/issues/new/choose"
        },
        SystemEntry () {
            name = _("Dock"),
            issues_url = "https://github.com/elementary/dock/issues/new/choose"
        },
        SystemEntry () {
            name = _("Lock or Login Screen"),
            issues_url = "https://github.com/elementary/greeter/issues/new/choose"
        },
        SystemEntry () {
            name = _("Look & Feel"),
            issues_url = "https://github.com/elementary/stylesheet/issues/new/choose"
        },
        SystemEntry () {
            name = _("Multitasking or Window Management"),
            issues_url = "https://github.com/elementary/gala/issues/new/choose"
        },
        SystemEntry () {
            name = _("Notifications"),
            issues_url = "https://github.com/elementary/notifications/issues/new/choose"
        },
        SystemEntry () {
            name = _("Welcome & Onboarding"),
            issues_url = "https://github.com/elementary/onboarding/issues/new/choose"
        },
        SystemEntry () {
            name = _("Panel"),
            issues_url = "https://github.com/elementary/wingpanel/issues/new/choose"
        }
    };

    private struct SwitchboardEntry {
        string icon;
        string id;
    }

    static SwitchboardEntry[] switchboard_entries = {
        SwitchboardEntry () {
            icon = "preferences-desktop-applications",
            id = "io.elementary.switchboard.applications"
        },
        SwitchboardEntry () {
            icon = "preferences-desktop-wallpaper",
            id = "io.elementary.switchboard.pantheon-shell"
        },
        SwitchboardEntry () {
            icon = "preferences-desktop-locale",
            id = "io.elementary.switchboard.locale"
        },
        SwitchboardEntry () {
            icon = "preferences-system-notifications",
            id = "io.elementary.switchboard.notifications"
        },
        SwitchboardEntry () {
            icon = "preferences-system-privacy",
            id = "io.elementary.switchboard.security-privacy"
        },
        SwitchboardEntry () {
            icon = "preferences-desktop-display",
            id = "io.elementary.switchboard.display"
        },
        SwitchboardEntry () {
            icon = "preferences-desktop-keyboard",
            id = "io.elementary.switchboard.keyboard"
        },
        SwitchboardEntry () {
            icon = "preferences-desktop-peripherals",
            id = "io.elementary.switchboard.mouse-touchpad"
        },
        SwitchboardEntry () {
            icon = "preferences-system-power",
            id = "io.elementary.switchboard.power"
        },
        SwitchboardEntry () {
            icon = "printer",
            id = "io.elementary.switchboard.printers"
        },
        SwitchboardEntry () {
            icon = "preferences-desktop-sound",
            id = "io.elementary.switchboard.sound"
        },
        SwitchboardEntry () {
            icon = "preferences-bluetooth",
            id = "io.elementary.switchboard.bluetooth"
        },
        SwitchboardEntry () {
            icon = "preferences-system-network",
            id = "io.elementary.switchboard.network"
        },
        SwitchboardEntry () {
            icon = "preferences-desktop-online-accounts",
            id = "io.elementary.switchboard.onlineaccounts"
        },
        SwitchboardEntry () {
            icon = "preferences-system-sharing",
            id = "io.elementary.switchboard.sharing"
        },
        SwitchboardEntry () {
            icon = "application-x-firmware",
            id = "io.elementary.switchboard.about"
        },
        SwitchboardEntry () {
            icon = "preferences-system-time",
            id = "io.elementary.switchboard.datetime"
        },
        SwitchboardEntry () {
            icon = "preferences-system-parental-controls",
            id = "io.elementary.switchboard.parental-controls"
        },
        SwitchboardEntry () {
            icon = "preferences-desktop-accessibility",
            id = "io.elementary.switchboard.a11y"
        },
        SwitchboardEntry () {
            icon = "system-users",
            id = "io.elementary.switchboard.useraccounts"
        },
        SwitchboardEntry () {
            icon = "input-tablet",
            id = "io.elementary.switchboard.wacom"
        }
    };

    private struct WingpanelEntry {
        string icon;
        string id;
    }

    static WingpanelEntry[] wingpanel_entries = {
        WingpanelEntry () {
            icon = "preferences-desktop-accessibility",
            id="io.elementary.wingpanel.a11y"
        },
        WingpanelEntry () {
            icon = "preferences-bluetooth",
            id="io.elementary.wingpanel.bluetooth"
        },
        WingpanelEntry () {
            icon = "preferences-system-time",
            id="io.elementary.wingpanel.datetime"
        },
        WingpanelEntry () {
            icon = "preferences-desktop-keyboard",
            id="io.elementary.wingpanel.keyboard"
        },
        WingpanelEntry () {
            icon = "preferences-system-network",
            id="io.elementary.wingpanel.network"
        },
        WingpanelEntry () {
            icon = "preferences-desktop-display",
            id="io.elementary.wingpanel.nightlight"
        },
        WingpanelEntry () {
            icon = "preferences-system-notifications",
            id="io.elementary.wingpanel.notifications"
        },
        WingpanelEntry () {
            icon = "preferences-system-power",
            id="io.elementary.wingpanel.power"
        },
        WingpanelEntry () {
            icon = "system-users",
            id="io.elementary.wingpanel.session"
        },
        WingpanelEntry () {
            icon = "preferences-desktop-sound",
            id="io.elementary.wingpanel.sound"
        }
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
