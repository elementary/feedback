project(
    'io.elementary.feedback',
    'vala', 'c',
    version: '8.0.1',
    meson_version: '>=0.58.0'
)

gnome = import('gnome')
i18n = import('i18n')

appstream_dep = dependency ('appstream', version: '>=0.12.10')

if appstream_dep.version().version_compare('>=0.15')
    add_project_arguments('--define=HAS_APPSTREAM_0_15', language:'vala')
endif
if appstream_dep.version().version_compare('>=1.0')
    add_project_arguments('--define=HAS_APPSTREAM_1_0', language:'vala')
endif

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Widgets/CategoryRow.vala',
    'src/Widgets/RepoRow.vala',
    config_file,
    dependencies: [
        appstream_dep,
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite-7', version: '>=7.0.0'),
        dependency('gtk4', version: '>= 4.10'),
        dependency('libadwaita-1', version: '>=1.0.0')
    ],
    install : true
)

subdir('data')
subdir('po')

gnome.post_install(glib_compile_schemas: true)
