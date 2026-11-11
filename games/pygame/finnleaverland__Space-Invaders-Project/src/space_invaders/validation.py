"""Rules for new accounts and passwords.

Each check returns an error message for the player, or None if everything is fine.
Kept separate from the screens so the rules can be tested without opening a window.
"""

MAX_USERNAME_LENGTH = 10
MIN_PASSWORD_LENGTH = 8  # in line with UK NCSC and NIST guidance

SECURITY_QUESTIONS = (
    "What was the name of your first pet?",
    "What city were you born in?",
    "What was the name of your first school?",
    "What is your favourite film?",
    "What was the model of your first phone?",
    "What is your oldest cousin's first name?",
)


def check_username(username):
    """Usernames are 1 to MAX_USERNAME_LENGTH characters with no commas (the file is CSV)."""
    if not 1 <= len(username) <= MAX_USERNAME_LENGTH:
        return f"Username must be 1 to {MAX_USERNAME_LENGTH} characters"
    if "," in username:
        return "Usernames can't contain commas"
    return None


def check_new_password(password, confirmation):
    """New passwords must be long enough and typed the same way twice."""
    if len(password) < MIN_PASSWORD_LENGTH:
        return f"Password must be at least {MIN_PASSWORD_LENGTH} characters"
    if password != confirmation:
        return "The passwords don't match"
    return None


def check_registration(username, password, confirmation, question, answer):
    """Check every box on the registration form, returning the first problem found."""
    return (
        check_username(username)
        or check_new_password(password, confirmation)
        or (None if question in SECURITY_QUESTIONS else "Choose a security question")
        or (None if answer.strip() else "Enter an answer to your security question")
    )
