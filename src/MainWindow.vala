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

public class Feedback.MainWindow : Gtk.ApplicationWindow {
    private uint configure_id;
    private Gtk.ListBox listbox;
    private Category? category_filter;

    // public IssueDialog () {
    //     Object (
    //         image_icon: new ThemedIcon (), 
    //         primary_text: ,
    //         secondary_text: ,
    //     );
    // }

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            icon_name: "bug",
            title: _("Feedback")
        );
    }

    construct {
        var titlebar = new Gtk.HeaderBar ();
        titlebar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        titlebar.set_custom_title (new Gtk.Grid ());

        var image_icon = new Gtk.Image.from_icon_name ("dialog-question", Gtk.IconSize.DIALOG);

        var primary_label = new Gtk.Label (_("Which of the Following Are You Seeing an Issue With?"));
        primary_label.xalign = 0;

        var secondary_label = new Gtk.Label (_("Please select a component from the list."));
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

        foreach (var app in app_entries) {
            var desktop_info = new DesktopAppInfo (app.app_id + ".desktop");
            var repo_row = new RepoRow (desktop_info.get_display_name (), desktop_info.get_icon (), Category.DEFAULT_APPS, app.issues_url);
            listbox.add (repo_row);
        }

        foreach (var entry in system_entries) {
            var repo_row = new RepoRow (entry.name, null, Category.SYSTEM, entry.issues_url);
            listbox.add (repo_row);
        }

        foreach (var entry in switchboard_entries) {
            var repo_row = new RepoRow (dgettext (entry.gettext_domain, entry.name), new ThemedIcon (entry.icon), Category.SETTINGS, entry.issues_url);
            listbox.add (repo_row);
        }

        foreach (var entry in wingpanel_entries) {
            var repo_row = new RepoRow (dgettext (entry.gettext_domain, entry.name), new ThemedIcon (entry.icon), Category.PANEL, entry.issues_url);
            listbox.add (repo_row);
        }

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (listbox);

        var repo_list_grid = new Gtk.Grid ();
        repo_list_grid.orientation = Gtk.Orientation.VERTICAL;
        repo_list_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        repo_list_grid.add (category_header);
        repo_list_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        repo_list_grid.add (scrolled);

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add (category_list);
        stack.add (repo_list_grid);

        var frame = new Gtk.Frame (null);
        frame.margin_top = frame.margin_bottom = 24;
        frame.add (stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.action_name = "app.quit";

        var report_button = new Gtk.Button.with_label (_("Report Problem"));
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

        category_list.row_activated.connect ((row) => {
            stack.visible_child = repo_list_grid;
            category_filter = ((CategoryRow) row).category;
            category_title.label = ((CategoryRow) row).category.to_string ();
            listbox.invalidate_filter ();
            var adjustment = scrolled.get_vadjustment ();
            adjustment.set_value (adjustment.lower);
        });

        back_button.clicked.connect (() => {
            stack.visible_child = category_list;
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
        });
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

    private struct AppEntry {
        string app_id;
        string issues_url;
    }

    static AppEntry[] app_entries = {
        AppEntry () {
            app_id = "io.elementary.appcenter",
            issues_url = "https://github.com/elementary/appcenter/issues/new"
        },
        AppEntry () {
            app_id = "io.elementary.calculator",
            issues_url = "https://github.com/elementary/calculator/issues/new"
        },
        AppEntry () {
            app_id = "io.elementary.calendar",
            issues_url = "https://github.com/elementary/calendar/issues/new"
        },
        AppEntry () {
            app_id = "io.elementary.camera",
            issues_url = "https://github.com/elementary/camera/issues/new"
        },
        AppEntry () {
            app_id = "io.elementary.code",
            issues_url = "https://github.com/elementary/code/issues/new"
        },
        AppEntry () {
            app_id = "org.gnome.Epiphany",
            issues_url = "https://gitlab.gnome.org/GNOME/epiphany/blob/master/CONTRIBUTING.md"
        },
        AppEntry () {
            app_id = "io.elementary.files",
            issues_url = "https://github.com/elementary/files/issues/new"
        },
        AppEntry () {
            app_id = "org.pantheon.mail",
            issues_url = "https://github.com/elementary/mail/issues/new"
        },
        AppEntry () {
            app_id = "io.elementary.music",
            issues_url = "https://github.com/elementary/music/issues/new"
        },
        AppEntry () {
            app_id = "io.elementary.photos",
            issues_url = "https://github.com/elementary/photos/issues/new"
        },
        AppEntry () {
            app_id = "io.elementary.screenshot-tool",
            issues_url = "https://github.com/elementary/screenshot/issues/new"
        },
        AppEntry () {
            app_id = "io.elementary.terminal",
            issues_url = "https://github.com/elementary/terminal/issues/new"
        },
        AppEntry () {
            app_id = "io.elementary.videos",
            issues_url = "https://github.com/elementary/videos/issues/new"
        }
    };

    private struct SystemEntry {
        string name;
        string issues_url;
    }

    static SystemEntry[] system_entries = {
        SystemEntry () {
            name = _("Applications Menu"),
            issues_url = "https://github.com/elementary/applications-menu/issues/new"
        },
        SystemEntry () {
            name = _("Lock or Login Screen"),
            issues_url = "https://github.com/elementary/greeter/issues/new"
        },
        SystemEntry () {
            name = _("Look & Feel"),
            issues_url = "https://github.com/elementary/stylesheet/issues/new"
        },
        SystemEntry () {
            name = _("Multitasking or Window Management"),
            issues_url = "https://github.com/elementary/gala/issues/new"
        },
        SystemEntry () {
            name = _("Notifications"),
            issues_url = "https://github.com/elementary/gala/issues/new"
        }
    };

    private struct SwitchboardEntry {
        string name;
        string gettext_domain;
        string icon;
        string issues_url;
    }

    static SwitchboardEntry[] switchboard_entries = {
        SwitchboardEntry () {
            name = "Applications",
            gettext_domain = "applications-plug",
            icon = "preferences-desktop-applications",
            issues_url = "https://github.com/elementary/switchboard-plug-applications/issues/new"
        },
        SwitchboardEntry () {
            name = "Desktop",
            gettext_domain = "pantheon-desktop-plug",
            icon = "preferences-desktop-wallpaper",
            issues_url = "https://github.com/elementary/switchboard-plug-pantheon-shell/issues/new"
        },
        SwitchboardEntry () {
            name = "Language & Region",
            gettext_domain = "locale-plug",
            icon = "preferences-desktop-locale",
            issues_url = "https://github.com/elementary/switchboard-plug-locale/issues/new"
        },
        SwitchboardEntry () {
            name = "Notifications",
            gettext_domain = "notifications-plug",
            icon = "preferences-system-notifications",
            issues_url = "https://github.com/elementary/switchboard-plug-notifications/issues/new"
        },
        SwitchboardEntry () {
            name = "Security & Privacy",
            gettext_domain = "pantheon-security-privacy-plug",
            icon = "preferences-system-privacy",
            issues_url = "https://github.com/elementary/switchboard-plug-security-privacy/issues/new"
        },
        SwitchboardEntry () {
            name = "Displays",
            gettext_domain = "pantheon-display-plug",
            icon = "preferences-desktop-display",
            issues_url = "https://github.com/elementary/switchboard-plug-display/issues/new"
        },
        SwitchboardEntry () {
            name = "Keyboard",
            gettext_domain = "keyboard-plug",
            icon = "preferences-desktop-keyboard",
            issues_url = "https://github.com/elementary/switchboard-plug-keyboard/issues/new"
        },
        SwitchboardEntry () {
            name = "Mouse & Touchpad",
            gettext_domain = "mouse-touchpad-plug",
            icon = "preferences-desktop-peripherals",
            issues_url = "https://github.com/elementary/switchboard-plug-mouse-touchpad/issues/new"
        },
        SwitchboardEntry () {
            name = "Power",
            gettext_domain = "power-plug",
            icon = "preferences-system-power",
            issues_url = "https://github.com/elementary/switchboard-plug-power/issues/new"
        },
        SwitchboardEntry () {
            name = "Printers",
            gettext_domain = "printers-plug",
            icon = "printer",
            issues_url = "https://github.com/elementary/switchboard-plug-printers/issues/new"
        },
        SwitchboardEntry () {
            name = "Sound",
            gettext_domain = "sound-plug",
            icon = "preferences-desktop-sound",
            issues_url = "https://github.com/elementary/switchboard-plug-sound/issues/new"
        },
        SwitchboardEntry () {
            name = "Bluetooth",
            gettext_domain = "bluetooth-plug",
            icon = "preferences-bluetooth",
            issues_url = "https://github.com/elementary/switchboard-plug-bluetooth/issues/new"
        },
        SwitchboardEntry () {
            name = "Network",
            gettext_domain = "networking-plug",
            icon = "preferences-system-network",
            issues_url = "https://github.com/elementary/switchboard-plug-networking/issues/new"
        },
        SwitchboardEntry () {
            name = "Online Accounts",
            gettext_domain = "pantheon-online-accounts",
            icon = "preferences-desktop-online-accounts",
            issues_url = "https://github.com/elementary/switchboard-plug-online-accounts/issues/new"
        },
        SwitchboardEntry () {
            name = "Sharing",
            gettext_domain = "sharing-plug",
            icon = "preferences-system-sharing",
            issues_url = "https://github.com/elementary/switchboard-plug-sharing/issues/new"
        },
        SwitchboardEntry () {
            name = "About",
            gettext_domain = "about-plug",
            icon = "dialog-information",
            issues_url = "https://github.com/elementary/switchboard-plug-about/issues/new"
        },
        SwitchboardEntry () {
            name = "Date & Time",
            gettext_domain = "datetime-plug",
            icon = "preferences-system-time",
            issues_url = "https://github.com/elementary/switchboard-plug-datetime/issues/new"
        },
        SwitchboardEntry () {
            name = "Parental Control",
            gettext_domain = "parental-controls-plug",
            icon = "preferences-system-parental-controls",
            issues_url = "https://github.com/elementary/switchboard-plug-parental-controls/issues/new"
        },
        SwitchboardEntry () {
            name = "Universal Access",
            gettext_domain = "accessibility-plug",
            icon = "preferences-desktop-accessibility",
            issues_url = "https://github.com/elementary/switchboard-plug-a11y/issues/new"
        },
        SwitchboardEntry () {
            name = "User Accounts",
            gettext_domain = "useraccounts-plug",
            icon = "system-users",
            issues_url = "https://github.com/elementary/switchboard-plug-accounts/issues/new"
        }
    };

    private struct WingpanelEntry {
        string name;
        string gettext_domain;
        string icon;
        string issues_url;
    }

    static WingpanelEntry[] wingpanel_entries = {
        WingpanelEntry () {
            name = "Bluetooth",
            gettext_domain = "bluetooth-plug",
            icon = "bluetooth-active-symbolic",
            issues_url = "https://github.com/elementary/wingpanel-indicator-bluetooth/issues/new"
        },
        WingpanelEntry () {
            name = "Date & Time",
            gettext_domain = "datetime-plug",
            icon = "appointment-symbolic",
            issues_url = "https://github.com/elementary/wingpanel-indicator-datetime/issues/new"
        },
        WingpanelEntry () {
            name = "Keyboard",
            gettext_domain = "keyboard-plug",
            icon = "input-keyboard-symbolic",
            issues_url = "https://github.com/elementary/wingpanel-indicator-keyboard/issues/new"
        },
        WingpanelEntry () {
            name = "Network",
            gettext_domain = "pantheon-network-plug",
            icon = "network-wireless-signal-excellent-symbolic",
            issues_url = "https://github.com/elementary/wingpanel-indicator-network/issues/new"
        },
        WingpanelEntry () {
            name = "Night Light",
            gettext_domain = "pantheon-display-plug",
            icon = "night-light-symbolic",
            issues_url = "https://github.com/elementary/wingpanel-indicator-nightlight/issues/new"
        },
        WingpanelEntry () {
            name = "Notifications",
            gettext_domain = "notifications-plug",
            icon = "notification-symbolic",
            issues_url = "https://github.com/elementary/wingpanel-indicator-notifications/issues/new"
        },
        WingpanelEntry () {
            name = "Power",
            gettext_domain = "power-plug",
            icon = "battery-full-symbolic",
            issues_url = "https://github.com/elementary/wingpanel-indicator-power/issues/new"
        },
        WingpanelEntry () {
            name = N_("Session"),
            gettext_domain = "about-plug",
            icon = "system-shutdown-symbolic",
            issues_url = "https://github.com/elementary/wingpanel-indicator-session/issues/new"
        },
        WingpanelEntry () {
            name = "Sound",
            gettext_domain = "sound-plug",
            icon = "audio-volume-high-symbolic",
            issues_url = "https://github.com/elementary/wingpanel-indicator-sound/issues/new"
        }
    };

    private enum Category {
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

    private class CategoryRow : Gtk.ListBoxRow {
        public Category category { get; construct; }

        public CategoryRow (Category category) {
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

    private class RepoRow : Gtk.ListBoxRow {
        public bool selected { get; set; }
        public Category category { get; construct; }
        public GLib.Icon? icon { get; construct; }
        public string title { get; construct; }
        public string url { get; construct; }

        public RepoRow (string title, GLib.Icon? icon, Category category, string url) {
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
