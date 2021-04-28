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

    construct {
        var titlebar = new Gtk.HeaderBar ();
        titlebar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        titlebar.set_custom_title (new Gtk.Grid ());

        var image_icon = new Gtk.Image.from_icon_name ("io.elementary.feedback", Gtk.IconSize.DIALOG);

        var primary_label = new Gtk.Label (_("Send feedback for which component?"));
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var secondary_label = new Gtk.Label (_("Select an item from the list to send feedback or report a problem from your web browser."));
        secondary_label.xalign = 0;

        var apps_category = new CategoryRow (Category.DEFAULT_APPS);
        var panel_category = new CategoryRow (Category.PANEL);
        var settings_category = new CategoryRow (Category.SETTINGS);
        var system_category = new CategoryRow (Category.SYSTEM);

        var category_list = new Gtk.ListBox ();
        category_list.activate_on_single_click = true;
        category_list.selection_mode = Gtk.SelectionMode.NONE;
        category_list.add (apps_category);
        category_list.add (panel_category);
        category_list.add (settings_category);
        category_list.add (system_category);

        var back_button = new Gtk.Button.with_label (_("Categories"));
        back_button.halign = Gtk.Align.START;
        back_button.margin = 6;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var category_title = new Gtk.Label ("");

        var category_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        category_header.pack_start (back_button);
        category_header.set_center_widget (category_title);

        listbox = new Gtk.ListBox ();
        listbox.expand = true;
        listbox.set_filter_func (filter_function);
        listbox.set_sort_func (sort_function);

        var appstream_pool = new AppStream.Pool ();
        try {
            bool sandboxed = FileUtils.test ("/.flatpak-info", FileTest.EXISTS);

            if (sandboxed) {
                appstream_pool.add_metadata_location ("/run/host/usr/share/metainfo/");
            } else {
                appstream_pool.set_flags (AppStream.PoolFlags.READ_METAINFO);
            }

            appstream_pool.load ();
        } catch (Error e) {
            critical (e.message);
        } finally {
            foreach (var app in app_entries) {
                appstream_pool.get_components_by_id (app).foreach ((component) => {
                    var repo_row = new RepoRow (
                        component.name,
                        icon_from_appstream_component (component),
                        Category.DEFAULT_APPS,
                        component.get_url (AppStream.UrlKind.BUGTRACKER)
                    );

                    listbox.add (repo_row);
                });
            }

            foreach (var entry in system_entries) {
                var repo_row = new RepoRow (entry.name, null, Category.SYSTEM, entry.issues_url);
                listbox.add (repo_row);
            }

            foreach (var entry in switchboard_entries) {
                appstream_pool.get_components_by_id (entry.id).foreach ((component) => {
                    var repo_row = new RepoRow (
                        component.name,
                        new ThemedIcon (entry.icon),
                        Category.SETTINGS,
                        component.get_url (AppStream.UrlKind.BUGTRACKER)
                    );

                    listbox.add (repo_row);
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

                    listbox.add (repo_row);
                });
            }
        }

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (listbox);

        var repo_list_grid = new Gtk.Grid ();
        repo_list_grid.orientation = Gtk.Orientation.VERTICAL;
        repo_list_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        repo_list_grid.add (category_header);
        repo_list_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        repo_list_grid.add (scrolled);

        var deck = new Hdy.Deck () {
            can_swipe_back = true
        };
        deck.add (category_list);
        deck.add (repo_list_grid);

        var frame = new Gtk.Frame (null);
        frame.margin_top = frame.margin_bottom = 24;
        frame.add (deck);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.action_name = "app.quit";

        var report_button = new Gtk.Button.with_label (_("Send Feedback…"));
        report_button.sensitive = false;
        report_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.spacing = 6;
        button_box.add (cancel_button);
        button_box.add (report_button);

        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.column_spacing = 12;
        grid.attach (image_icon, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (frame, 1, 2);
        grid.attach (button_box, 0, 3, 2);

        add (grid);
        get_style_context ().add_class ("rounded");
        set_titlebar (titlebar);

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        category_list.row_activated.connect ((row) => {
            deck.visible_child = repo_list_grid;
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
                AppInfo.launch_default_for_uri ("%s".printf (url), null);
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
         "org.gnome.Epiphany",
         "io.elementary.files",
         "org.pantheon.mail",
         "io.elementary.music",
         "io.elementary.photos",
         "io.elementary.screenshot-tool",
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
            issues_url = "https://github.com/elementary/gala/issues/new/choose"
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
            icon = "dialog-information",
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
        }
    };

    private struct WingpanelEntry {
        string icon;
        string id;
    }

    static WingpanelEntry[] wingpanel_entries = {
        WingpanelEntry () {
            icon = "bluetooth-active-symbolic",
            id="io.elementary.wingpanel.bluetooth"
        },
        WingpanelEntry () {
            icon = "appointment-symbolic",
            id="io.elementary.wingpanel.datetime"
        },
        WingpanelEntry () {
            icon = "input-keyboard-symbolic",
            id="io.elementary.wingpanel.keyboard"
        },
        WingpanelEntry () {
            icon = "network-wireless-signal-excellent-symbolic",
            id="io.elementary.wingpanel.network"
        },
        WingpanelEntry () {
            icon = "night-light-symbolic",
            id="io.elementary.wingpanel.nightlight"
        },
        WingpanelEntry () {
            icon = "notification-symbolic",
            id="io.elementary.wingpanel.notifications"
        },
        WingpanelEntry () {
            icon = "battery-full-symbolic",
            id="io.elementary.wingpanel.power"
        },
        WingpanelEntry () {
            icon = "system-shutdown-symbolic",
            id="io.elementary.wingpanel.session"
        },
        WingpanelEntry () {
            icon = "audio-volume-high-symbolic",
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
