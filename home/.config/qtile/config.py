import os
import subprocess

from libqtile import bar, hook, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~')
    subprocess.Popen([home + '/.config/qtile/autostart.sh'])

def refresh():
    subprocess.Popen(['autorandr', '-c'])
    lazy.reload_config()

mod = 'mod4'
terminal = guess_terminal()

keys = [
    Key([mod], 'h', lazy.layout.left(),
        desc='Move focus to left'),
    Key([mod], 'l', lazy.layout.right(),
        desc='Move focus to right'),
    Key([mod], 'j', lazy.layout.down(),
        desc='Move focus down'),
    Key([mod], 'k', lazy.layout.up(),
        desc='Move focus up'),
    Key([mod], 'Tab', lazy.layout.next(),
        desc='Move window focus to other window'),

    Key([mod, 'shift'], 'h', lazy.layout.shuffle_left(),
        desc='Move window to the left'),
    Key([mod, 'shift'], 'l', lazy.layout.shuffle_right(),
        desc='Move window to the right'),
    Key([mod, 'shift'], 'j', lazy.layout.shuffle_down(),
        desc='Move window down'),
    Key([mod, 'shift'], 'k', lazy.layout.shuffle_up(),
        desc='Move window up'),

    Key([mod], 'i', lazy.layout.grow(),
        desc='Grow window'),
    Key([mod], 'o', lazy.layout.shrink(),
        desc='Shrink window'),
    Key([mod], 'n', lazy.layout.reset(),
        desc='Reset all window sizes'),

    Key([mod], 'Return', lazy.spawn(terminal),
        desc='Launch terminal'),
    Key([mod], 'space', lazy.next_layout(),
        desc='Toggle between layouts'),
    Key([mod], 'w', lazy.window.kill(),
        desc='Kill focused window'),
    Key([mod, 'control'], 'l',
        lazy.spawn('i3lock-fancy'), desc='Lock the screen'),
    Key([mod, 'control'], 'r',
        refresh(), desc='Reload the config'),
    Key([mod, 'control'], 'q',
        lazy.shutdown(), desc='Shutdown Qtile'),
    Key([mod], 'r', lazy.spawncmd(),
        desc='Spawn a command using a prompt widget'),
]

groups = [Group(i) for i in '123456789']

for i in groups:
    keys.extend([
        # mod1 + letter of group = switch to group
        Key([mod], i.name, lazy.group[i.name].toscreen(),
            desc='Switch to group {}'.format(i.name)),

        # mod1 + shift + letter of group = switch to & move focused window to group
        Key([mod, 'shift'], i.name, lazy.window.togroup(i.name, switch_group=True),
            desc='Switch to & move focused window to group {}'.format(i.name)),
    ])

colors = {
    'foreground': ('#ffffff', '#CAD3C8'),
    'background': ('#636e72', '#2d3436'),
    'error': ('#B33771', '#6D214F'),
    'warn': ('#F8EFBA', '#EAB543'),
    'info': ('#25CCF7', '#1B9CFC'),
    'debug': ('#55E6C1', '#58B19F'),
    'trace': ('#FEA47F', '#F97F51'),
}

layouts = [
    layout.MonadTall(
        margin=16,
        border_width=0,
    ),
    layout.Max(),
]

widget_defaults = dict(
    font='mono bold',
    fontsize=18,
    padding=8,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    disable_drag=True,
                    highlight_method='block',
                    active=colors['foreground'][0],
                    inactive=colors['background'][0],
                    this_screen_border=colors['info'][1],
                    this_current_screen_border=colors['info'][1],
                ),
                widget.Prompt(
                    font='mono',
                    bell_style='visual',
                    cursor_color=colors['foreground'][0],
                    foreground=colors['foreground'][0],
                    prompt='> ',
                    visual_bell_color=colors['error'][0],
                ),
                widget.WindowCount(
                    background=colors['trace'][1],
                    foreground=colors['foreground'][0],
                    show_zero=True,
                ),
                widget.WindowName(
                    empty_group_string='no active window',
                    background=colors['info'][1],
                    foreground=colors['foreground'][0],
                ),
                widget.Systray(
                    icon_size=24,
                ),
                widget.Clock(
                    format='%a, %B %d %I:%M%p',
                    foreground=colors['foreground'][0],
                ),
            ],
            32,
            margin=[16, 16, 0, 16],
            background=colors['background'][1],
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], 'Button1', lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], 'Button3', lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], 'Button2', lazy.window.bring_to_front())
]

dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = False
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    border_width=0,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class='confirmreset'),  # gitk
        Match(wm_class='makebranch'),  # gitk
        Match(wm_class='maketag'),  # gitk
        Match(wm_class='ssh-askpass'),  # ssh-askpass
        Match(title='branchdialog'),  # gitk
        Match(title='pinentry'),  # GPG key password entry
    ],
)
auto_fullscreen = True
focus_on_window_activation = 'smart'
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True
wmname = 'LG3D'
