"""Tests for the registration and password rules."""
import pytest

from space_invaders.validation import (
    MAX_USERNAME_LENGTH,
    MIN_PASSWORD_LENGTH,
    SECURITY_QUESTIONS,
    check_new_password,
    check_registration,
    check_username,
)

QUESTION = SECURITY_QUESTIONS[0]


@pytest.mark.parametrize("username", ["a", "alice", "x" * MAX_USERNAME_LENGTH, "Bob_99"])
def test_valid_usernames(username):
    assert check_username(username) is None


@pytest.mark.parametrize("username, problem", [
    ("", "1 to 10 characters"),
    ("x" * (MAX_USERNAME_LENGTH + 1), "1 to 10 characters"),
    ("a,b", "commas"),
])
def test_invalid_usernames(username, problem):
    assert problem in check_username(username)


def test_password_must_be_long_enough():
    short = "x" * (MIN_PASSWORD_LENGTH - 1)
    assert "at least 8" in check_new_password(short, short)
    exact = "x" * MIN_PASSWORD_LENGTH
    assert check_new_password(exact, exact) is None


def test_passwords_must_match():
    assert check_new_password("long-password", "long-passw0rd") == "The passwords don't match"


def test_commas_are_allowed_in_passwords():
    # passwords are hashed before saving, so commas can't break the file any more
    assert check_new_password("a,b,c,d,e", "a,b,c,d,e") is None


def test_valid_registration():
    assert check_registration("alice", "long-password", "long-password", QUESTION, "Rex") is None


@pytest.mark.parametrize("question", ["", "My own question?"])
def test_registration_needs_a_preset_question(question):
    assert check_registration("alice", "long-password", "long-password", question, "Rex") == \
        "Choose a security question"


def test_registration_needs_an_answer():
    assert check_registration("alice", "long-password", "long-password", QUESTION, "   ") == \
        "Enter an answer to your security question"


def test_registration_reports_the_first_problem():
    assert "Username" in check_registration("", "short", "other", "", "")


def test_preset_questions_fit_in_the_file():
    assert all("," not in question for question in SECURITY_QUESTIONS)
