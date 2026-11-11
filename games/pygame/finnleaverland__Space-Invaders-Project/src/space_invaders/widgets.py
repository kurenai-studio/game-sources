"""Building blocks shared by every screen in the main window."""
import tkinter as tk
from tkinter import ttk

from . import theme

PASSWORD_MASK = "•"
EDITING_KEYS = ("BackSpace", "Delete")


class Screen(ttk.Frame):
    """One page of the main window, e.g. the login form or the menu.

    Subclasses add their widgets to self.body in build(); the body is kept in the middle
    of the window. Keyboard behaviour is the same on every screen:
      - the cursor starts in the first text box (or on the first button)
      - Return submits the form, or presses the button that has keyboard focus
      - Escape does the same as the Back button
      - typing in a box clears the error message
    """

    def __init__(self, parent, app, **options):
        super().__init__(parent, padding=theme.px(theme.PADDING))
        self.app = app
        self.options = options
        self.message = None
        self.fields = []  # text boxes, top to bottom
        self.password_fields = []
        self.buttons = []
        self.submit_command = None  # what Return does
        self.back_command = None  # what Escape does
        self.body = ttk.Frame(self)
        self.body.pack(expand=True, fill="x")  # expand without filling vertically = centred
        self.build()

    def build(self):
        """Create the screen's widgets."""

    def on_show(self):
        """Put the cursor in the first text box, or on the first button if there are none."""
        first = self.fields[0] if self.fields else (self.buttons[0] if self.buttons else None)
        if first is not None:
            first.focus_set()

    # --- Keyboard handling (bound to the main window by App) -------------------------

    def handle_return(self, event=None):
        focused = event.widget if event is not None else self.focus_get()
        if isinstance(focused, ttk.Button):
            focused.invoke()
        elif self.submit_command is not None:
            self.submit_command()
        return "break"

    def handle_escape(self, event=None):
        if self.back_command is not None:
            self.back_command()
        return "break"

    def on_typing(self, event):
        """Clear the error message when the player edits a box (not for Tab, Shift, etc.)."""
        if (event.char and event.char.isprintable()) or event.keysym in EDITING_KEYS:
            self.clear_message()

    # --- Helpers for laying out a screen top to bottom ------------------------------

    def add_title(self, text, subtitle=None):
        ttk.Label(self.body, text=text, style="Title.TLabel").pack(pady=(0, theme.px(4)))
        if subtitle:
            ttk.Label(self.body, text=subtitle, style="Muted.TLabel").pack(pady=(0, theme.px(theme.GAP)))

    def add_heading(self, text):
        ttk.Label(self.body, text=text, style="Heading.TLabel").pack(pady=(0, theme.px(theme.GAP)))

    def add_field(self, label, hidden=False, parent=None):
        """Add a label and a text box underneath it. Returns the text box."""
        parent = parent or self.body
        ttk.Label(parent, text=label, style="Muted.TLabel").pack(
            fill="x", pady=(theme.px(theme.FIELD_GAP), 0))
        entry = ttk.Entry(parent, show=PASSWORD_MASK if hidden else "")
        entry.pack(fill="x", pady=theme.px(theme.FIELD_GAP))
        entry.bind("<Key>", self.on_typing, add="+")
        self.fields.append(entry)
        if hidden:
            self.password_fields.append(entry)
        return entry

    def add_choice(self, label, choices, placeholder):
        """Add a label and a drop-down list the player must pick from. Returns the list."""
        ttk.Label(self.body, text=label, style="Muted.TLabel").pack(
            fill="x", pady=(theme.px(theme.FIELD_GAP), 0))
        choice = ttk.Combobox(self.body, values=choices, state="readonly")
        choice.set(placeholder)
        choice.pack(fill="x", pady=theme.px(theme.FIELD_GAP))
        choice.bind("<<ComboboxSelected>>", lambda event: self.clear_message(), add="+")
        self.fields.append(choice)
        return choice

    def add_password_toggle(self, parent=None):
        """Add a "Show password" tick box that reveals every password box on the screen."""
        showing = tk.BooleanVar(value=False)

        def toggle():
            for entry in self.password_fields:
                entry.configure(show="" if showing.get() else PASSWORD_MASK)

        toggle_box = ttk.Checkbutton(parent or self.body, text="Show password", variable=showing,
                                     command=toggle, takefocus=False)
        toggle_box.pack(anchor="w", pady=(0, theme.px(theme.FIELD_GAP)))
        return toggle_box

    def add_button(self, text, command, primary=False, parent=None):
        style = "Accent.TButton" if primary else "TButton"
        button = ttk.Button(parent or self.body, text=text, command=command, style=style)
        button.pack(fill="x", pady=(theme.px(theme.GAP // 2), 0))
        self.buttons.append(button)
        return button

    def add_message_line(self):
        """Add the line under a form where errors and confirmations appear."""
        self.message = ttk.Label(self.body, text="", style="Error.TLabel",
                                 wraplength=theme.px(theme.TEXT_WIDTH), justify="center")
        self.message.pack(pady=(theme.px(theme.GAP // 2), 0))
        initial = self.options.get("message")
        if initial:
            self.show_success(initial)
        return self.message

    def add_back_button(self, command, text="← Back"):
        """Add the Back button at the bottom of the screen. Escape does the same."""
        self.back_command = command
        ttk.Button(self.body, text=text, command=command, style="Link.TButton").pack(
            pady=(theme.px(theme.GAP), 0))

    # --- Messages ------------------------------------------------------------------

    def show_error(self, text):
        self.message.configure(text=text, style="Error.TLabel")

    def show_success(self, text):
        self.message.configure(text=text, style="Success.TLabel")

    def clear_message(self):
        if self.message is not None:
            self.message.configure(text="")
