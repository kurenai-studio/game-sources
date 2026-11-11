"""Screens shown before logging in: welcome, log in, register and reset password."""
from tkinter import ttk

from . import theme
from .accounts import Client, ClientList
from .validation import (
    MAX_USERNAME_LENGTH,
    MIN_PASSWORD_LENGTH,
    SECURITY_QUESTIONS,
    check_new_password,
    check_registration,
)
from .widgets import Screen

QUESTION_PLACEHOLDER = "Choose a question…"


def find_client(username):
    """Look up a username in a freshly loaded client list.

    The file is re-read every time because scores are saved to it after each game.
    Returns (client_list, client), with client None if the username doesn't exist.
    """
    clients = ClientList()
    found, index = clients.find(Client(username))
    return clients, clients.clients[index] if found else None


class WelcomeScreen(Screen):
    """The first screen: choose to log in, register or reset a password."""

    def build(self):
        self.add_title("SPACE INVADERS", "Defend the planet. Beat the high score.")
        self.add_button("Log in", lambda: self.app.show("login"), primary=True)
        self.add_button("Register", lambda: self.app.show("register"))
        self.add_button("Reset password", lambda: self.app.show("reset_password"))
        self.add_message_line()
        self.add_back_button(self.app.quit, text="Quit")
        self.back_command = None  # Escape shouldn't close the game


class LoginScreen(Screen):
    """Log in with a username and password."""

    def build(self):
        self.add_title("Log in")
        self.username_entry = self.add_field("Username")
        self.password_entry = self.add_field("Password", hidden=True)
        self.add_password_toggle()
        self.add_button("Log in", self.submit, primary=True)
        self.add_message_line()
        self.add_back_button(lambda: self.app.show("welcome"))
        self.submit_command = self.submit

    def submit(self):
        clients, client = find_client(self.username_entry.get().strip())
        if client is None:
            self.show_error("Incorrect username")
            self.username_entry.focus_set()
        elif not client.check_password(self.password_entry.get()):
            self.password_entry.delete(0, "end")
            self.password_entry.focus_set()
            self.show_error("Incorrect password")
        else:
            self.app.log_in(client)


class RegisterScreen(Screen):
    """Create a new account."""

    def build(self):
        self.add_title("Create account")
        self.username_entry = self.add_field(f"Username (up to {MAX_USERNAME_LENGTH} characters)")
        self.password_entry = self.add_field(f"Password (at least {MIN_PASSWORD_LENGTH} characters)",
                                             hidden=True)
        self.confirm_entry = self.add_field("Confirm password", hidden=True)
        self.add_password_toggle()
        self.question_choice = self.add_choice("Security question", SECURITY_QUESTIONS,
                                               QUESTION_PLACEHOLDER)
        self.answer_entry = self.add_field("Answer")
        self.add_button("Create account", self.submit, primary=True)
        self.add_message_line()
        self.add_back_button(lambda: self.app.show("welcome"))
        self.submit_command = self.submit

    def submit(self):
        username = self.username_entry.get().strip()
        password = self.password_entry.get()
        question = self.question_choice.get()
        answer = self.answer_entry.get().strip()

        problem = check_registration(username, password, self.confirm_entry.get(), question, answer)
        if problem is None:
            clients, existing = find_client(username)
            if existing is not None:
                problem = "That username is already taken"
        if problem is not None:
            self.show_error(problem)
            return
        new_client = Client.new(username, password, question, answer)
        clients.add_client(new_client)
        self.app.log_in(new_client)


class ResetPasswordScreen(Screen):
    """Reset a forgotten password by answering the account's security question.

    Step 1 asks for the username; step 2 shows the question and asks for the answer
    and a new password.
    """

    def build(self):
        self.client = None
        self.clients = None
        self.add_title("Reset password")
        self.username_entry = self.add_field("Username")
        self.next_button = self.add_button("Next", self.find_account, primary=True)

        # Step 2, shown once the username is found
        self.step_two = ttk.Frame(self.body)
        self.question_label = ttk.Label(self.step_two, text="", wraplength=theme.px(theme.TEXT_WIDTH),
                                        justify="center")
        self.question_label.pack(pady=(theme.px(theme.GAP), 0))
        self.answer_entry = self.add_field("Answer", parent=self.step_two)
        self.password_entry = self.add_field(f"New password (at least {MIN_PASSWORD_LENGTH} characters)",
                                             hidden=True, parent=self.step_two)
        self.confirm_entry = self.add_field("Confirm new password", hidden=True, parent=self.step_two)
        self.add_password_toggle(parent=self.step_two)
        self.add_button("Save new password", self.submit, primary=True, parent=self.step_two)

        self.add_message_line()
        self.add_back_button(lambda: self.app.show("welcome"))
        self.submit_command = self.find_account

    def find_account(self):
        self.clients, self.client = find_client(self.username_entry.get().strip())
        if self.client is None:
            self.show_error("That username doesn't exist")
            return
        self.clear_message()
        self.username_entry.state(["disabled"])
        self.next_button.pack_forget()
        self.question_label.configure(text=self.client.question)
        self.step_two.pack(fill="x", after=self.username_entry)
        self.answer_entry.focus_set()
        self.submit_command = self.submit

    def submit(self):
        new_password = self.password_entry.get()
        problem = check_new_password(new_password, self.confirm_entry.get())
        if not self.client.check_answer(self.answer_entry.get()):
            self.show_error("Wrong answer, try again")
            self.answer_entry.focus_set()
        elif problem is not None:
            self.show_error(problem)
            self.password_entry.focus_set()
        else:
            self.client.set_password(new_password)
            self.clients.save_list()
            self.app.show("login", message="Password changed. Log in with your new password.")
