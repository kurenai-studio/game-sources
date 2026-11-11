"""The dark, space-themed look shared by every tkinter screen: colours, fonts and ttk styles.

Sizes in this file are for a normal 96 DPI screen. px() scales them for the real screen,
so the window looks the same (and stays sharp) with Windows display scaling turned on.
"""
import ctypes
import sys
import tkinter as tk
from tkinter import font as tkfont
from tkinter import ttk

# Colour palette
BACKGROUND = "#0b0e1f"  # deep space navy
SURFACE = "#161b36"  # input boxes and table background
SURFACE_HOVER = "#212849"
BORDER = "#2c3560"
ACCENT = "#4fc3f7"  # matches the blue player ship
ACCENT_HOVER = "#7dd5fa"
ACCENT_TEXT = "#06121f"  # text on accent-coloured buttons
TEXT = "#e8ecf8"
MUTED = "#8d94b3"
ERROR = "#ff6b6b"
SUCCESS = "#6bdc8f"
HIGHLIGHT = "#24407a"  # the logged-in player's leaderboard row

# One font family for every screen (the first one installed is used)
FONT_FAMILIES = ("Segoe UI", "Helvetica Neue", "Helvetica", "DejaVu Sans", "Arial")
TITLE_SIZE = 24
HEADING_SIZE = 16
BODY_SIZE = 11
SMALL_SIZE = 9

# Spacing (pixels at 96 DPI)
PADDING = 24  # around each screen
GAP = 12  # between groups of widgets
FIELD_GAP = 4  # between a label and its box
TEXT_WIDTH = 440  # where long lines of text wrap

STANDARD_DPI = 96
_scale = 1.0  # screen DPI / 96, set when the window is created


def px(size):
    """Scale a size in pixels (at 96 DPI) to the real screen."""
    return round(size * _scale)


def enable_dpi_awareness():
    """Ask Windows not to stretch (and blur) the windows; we scale them ourselves instead."""
    if sys.platform == "win32":
        try:
            ctypes.windll.shcore.SetProcessDpiAwareness(1)
        except (AttributeError, OSError):
            pass  # older Windows versions: keep the default behaviour


def pick_font_family(root):
    """Return the first font family from FONT_FAMILIES that is installed."""
    installed = set(tkfont.families(root))
    return next((family for family in FONT_FAMILIES if family in installed), "TkDefaultFont")


def apply_theme(root):
    """Set the window background and configure every ttk style used by the screens."""
    global _scale
    _scale = root.winfo_fpixels("1i") / STANDARD_DPI
    family = pick_font_family(root)
    body = (family, BODY_SIZE)
    root.configure(background=BACKGROUND)

    # Drop-down lists of comboboxes are plain tk widgets, so they are styled separately
    root.option_add("*TCombobox*Listbox.background", SURFACE)
    root.option_add("*TCombobox*Listbox.foreground", TEXT)
    root.option_add("*TCombobox*Listbox.selectBackground", ACCENT)
    root.option_add("*TCombobox*Listbox.selectForeground", ACCENT_TEXT)
    root.option_add("*TCombobox*Listbox.font", body)

    style = ttk.Style(root)
    style.theme_use("clam")
    style.configure(".", background=BACKGROUND, foreground=TEXT, font=body,
                    bordercolor=BORDER, lightcolor=BORDER, darkcolor=BORDER,
                    troughcolor=SURFACE, focuscolor=ACCENT)

    style.configure("TFrame", background=BACKGROUND)
    style.configure("TLabel", background=BACKGROUND, foreground=TEXT)
    style.configure("Title.TLabel", font=(family, TITLE_SIZE, "bold"), foreground=ACCENT)
    style.configure("Heading.TLabel", font=(family, HEADING_SIZE, "bold"))
    style.configure("Muted.TLabel", foreground=MUTED)
    style.configure("Small.TLabel", foreground=MUTED, font=(family, SMALL_SIZE))
    style.configure("Error.TLabel", foreground=ERROR)
    style.configure("Success.TLabel", foreground=SUCCESS)

    style.configure("TButton", background=SURFACE, foreground=TEXT, padding=(px(16), px(8)),
                    borderwidth=1, focusthickness=1)
    style.map("TButton",
              background=[("pressed", BORDER), ("active", SURFACE_HOVER)],
              bordercolor=[("focus", ACCENT)])
    style.configure("Accent.TButton", background=ACCENT, foreground=ACCENT_TEXT,
                    font=(family, BODY_SIZE, "bold"))
    style.map("Accent.TButton",
              background=[("pressed", ACCENT), ("active", ACCENT_HOVER)],
              foreground=[("active", ACCENT_TEXT)])
    style.configure("Link.TButton", background=BACKGROUND, foreground=MUTED,
                    borderwidth=0, padding=(px(4), px(4)))
    style.map("Link.TButton", background=[("active", BACKGROUND)], foreground=[("active", TEXT)])

    style.configure("TEntry", fieldbackground=SURFACE, foreground=TEXT, insertcolor=TEXT,
                    padding=px(6), bordercolor=BORDER)
    style.map("TEntry", bordercolor=[("focus", ACCENT)], lightcolor=[("focus", ACCENT)])

    style.configure("TCombobox", fieldbackground=SURFACE, background=SURFACE, foreground=TEXT,
                    arrowcolor=TEXT, arrowsize=px(12), padding=px(6))
    style.map("TCombobox",
              fieldbackground=[("readonly", SURFACE)], foreground=[("readonly", TEXT)],
              selectbackground=[("readonly", SURFACE)], selectforeground=[("readonly", TEXT)],
              bordercolor=[("focus", ACCENT)])

    style.configure("TCheckbutton", background=BACKGROUND, foreground=MUTED,
                    indicatorbackground=SURFACE, indicatorforeground=ACCENT,
                    indicatorsize=px(14), indicatormargin=(0, 0, px(6), 0))
    style.map("TCheckbutton", background=[("active", BACKGROUND)], foreground=[("active", TEXT)])

    style.configure("Horizontal.TScale", background=ACCENT, troughcolor=SURFACE,
                    bordercolor=BORDER, lightcolor=ACCENT, darkcolor=ACCENT,
                    sliderlength=px(18), sliderthickness=px(18), gripcount=0)
    style.map("Horizontal.TScale", background=[("active", ACCENT_HOVER)])

    style.configure("Treeview", background=SURFACE, fieldbackground=SURFACE, foreground=TEXT,
                    rowheight=px(28), borderwidth=0)
    style.map("Treeview", background=[("selected", ACCENT)], foreground=[("selected", ACCENT_TEXT)])
    style.configure("Treeview.Heading", background=BACKGROUND, foreground=MUTED,
                    font=(family, SMALL_SIZE, "bold"), relief="flat")
    style.map("Treeview.Heading", background=[("active", BACKGROUND)])
    return family


def centre_window(root, width, height):
    """Size a window and place it in the middle of the screen."""
    root.update_idletasks()
    x = (root.winfo_screenwidth() - width) // 2
    y = (root.winfo_screenheight() - height) // 3  # slightly above centre looks more natural
    root.geometry(f"{width}x{height}+{max(x, 0)}+{max(y, 0)}")


def new_root(title, width, height):
    """Create the themed main window."""
    enable_dpi_awareness()
    root = tk.Tk()
    root.title(title)
    apply_theme(root)
    centre_window(root, px(width), px(height))
    root.resizable(False, False)
    return root
