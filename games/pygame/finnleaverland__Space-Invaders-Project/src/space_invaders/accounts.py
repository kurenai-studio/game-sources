"""Player accounts: the Client record, and the ClientList that stores clients in a CSV file.

Each line of the file is: username, password hash, security question, security answer hash,
last score, highest score.

Passwords and security answers are never stored as plain text. They are hashed with
PBKDF2-HMAC-SHA256 using a random salt for every value, and stored as
"pbkdf2_sha256$<iterations>$<salt hex>$<hash hex>". Files written by older versions of
the game, which stored plain text, are upgraded automatically the next time they load.
"""
import csv
import hashlib
import hmac
import os
import secrets

# The client file lives in the project folder, so it works whatever folder you run from
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLIENT_FILE = os.path.join(PROJECT_ROOT, "Clientfile.txt")

FIELD_COUNT = 6  # username, password hash, question, answer hash, score, highest score
REQUIRED_FIELDS = 4  # lines without the two score columns are still accepted

HASH_NAME = "pbkdf2_sha256"
HASH_ITERATIONS = 600_000  # OWASP's recommended minimum for PBKDF2-HMAC-SHA256
SALT_BYTES = 16


def to_int(value):
    """Convert a score read from the file to an int. Blank or invalid values become 0."""
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def hash_secret(secret, iterations=None):
    """Hash a password or security answer with a new random salt.

    Returns a string holding everything needed to check it later:
    "pbkdf2_sha256$<iterations>$<salt hex>$<hash hex>".
    """
    iterations = iterations or HASH_ITERATIONS
    salt = secrets.token_bytes(SALT_BYTES)
    digest = hashlib.pbkdf2_hmac("sha256", secret.encode("utf-8"), salt, iterations)
    return f"{HASH_NAME}${iterations}${salt.hex()}${digest.hex()}"


def is_hashed(value):
    """Return True if a value from the file is a hash made by hash_secret()."""
    parts = value.split("$")
    if len(parts) != 4 or parts[0] != HASH_NAME or not parts[1].isdigit():
        return False
    try:
        bytes.fromhex(parts[2])
        bytes.fromhex(parts[3])
    except ValueError:
        return False
    return True


def verify_secret(secret, stored_hash):
    """Check a password or answer against a stored hash."""
    if not is_hashed(stored_hash):
        return False
    _, iterations, salt_hex, digest_hex = stored_hash.split("$")
    digest = hashlib.pbkdf2_hmac("sha256", secret.encode("utf-8"), bytes.fromhex(salt_hex), int(iterations))
    return hmac.compare_digest(digest.hex(), digest_hex)


def normalise_answer(answer):
    """Security answers ignore capital letters and surrounding spaces."""
    return answer.strip().lower()


class Client:
    """One player account. Clients are compared and sorted by username.

    Use Client.new() to create an account from a plain password and answer; the
    constructor itself takes the values exactly as they are stored in the file.
    """

    def __init__(self, username="", password_hash="", question="", answer_hash="",
                 score=0, highest_score=0):
        self.username = username
        self.password_hash = password_hash
        self.question = question
        self.answer_hash = answer_hash
        self.score = to_int(score)
        self.highest_score = to_int(highest_score)

    @classmethod
    def new(cls, username, password, question, answer):
        """Create a new account, hashing the password and security answer."""
        return cls(username, hash_secret(password), question, hash_secret(normalise_answer(answer)))

    def check_password(self, password):
        """Return True if the password is correct."""
        return verify_secret(password, self.password_hash)

    def check_answer(self, answer):
        """Return True if the security answer is correct (ignoring case and spaces)."""
        return verify_secret(normalise_answer(answer), self.answer_hash)

    def set_password(self, new_password):
        """Replace the password (call ClientList.save_list() afterwards to keep it)."""
        self.password_hash = hash_secret(new_password)

    def upgrade_plain_text(self):
        """Hash a password or answer loaded as plain text from an old file.

        Returns True if anything changed.
        """
        changed = False
        if not is_hashed(self.password_hash):
            self.password_hash = hash_secret(self.password_hash)
            changed = True
        if not is_hashed(self.answer_hash):
            self.answer_hash = hash_secret(normalise_answer(self.answer_hash))
            changed = True
        return changed

    def __eq__(self, other):
        return self.username == other.username

    def __lt__(self, other):
        return self.username < other.username

    def __gt__(self, other):
        return self.username > other.username

    def to_row(self):
        """Return the client's fields as a list of strings, ready to be written to the file."""
        return [self.username, self.password_hash, self.question, self.answer_hash,
                str(self.score), str(self.highest_score)]

    def __str__(self):
        return ", ".join(self.to_row())


class ClientList:
    """All the player accounts, loaded from and saved to the client file.

    The list is always kept sorted by username so that the binary search works.
    """

    def __init__(self, path=None):
        self.path = path or CLIENT_FILE
        self.clients = []
        if not os.path.exists(self.path):
            open(self.path, "w").close()  # first run: create an empty client file
        with open(self.path, "r", newline="") as f:
            # skipinitialspace also reads the older "a, b, c" style of file
            for fields in csv.reader(f, skipinitialspace=True):
                if len(fields) < REQUIRED_FIELDS:
                    continue  # skip blank or broken lines
                fields += ["0"] * (FIELD_COUNT - len(fields))  # missing scores count as 0
                self.clients.append(Client(*fields[:FIELD_COUNT]))
        self.sort_list()

        # Older versions stored plain text: hash it now and save, so it never stays on disk
        upgraded = [client.upgrade_plain_text() for client in self.clients]
        if any(upgraded):
            self.save_list()

    def __len__(self):
        return len(self.clients)

    def __str__(self):
        return "".join(str(client) + "\n" for client in self.clients)

    def sort_list(self):
        """Sort the clients by username using an insertion sort."""
        for i in range(1, len(self.clients)):
            current_item = self.clients[i]
            index = i
            while index > 0 and current_item < self.clients[index - 1]:
                self.clients[index] = self.clients[index - 1]
                index -= 1
            self.clients[index] = current_item

    def find(self, client):
        """Look for a client with the same username.

        Returns (True, index) if they are found, otherwise (False, -1).
        """
        index = self.binary_search(client, 0, len(self.clients) - 1)
        if index >= 0:
            return (True, index)
        return (False, -1)

    def binary_search(self, searched_client, lower, upper):
        """Recursive binary search for a client by username between two indexes.

        Returns the client's index, or -1 if they aren't in the list.
        """
        if lower > upper:
            return -1
        mid = (upper + lower) // 2
        if searched_client > self.clients[mid]:
            return self.binary_search(searched_client, mid + 1, upper)
        elif searched_client < self.clients[mid]:
            return self.binary_search(searched_client, lower, mid - 1)
        else:
            return mid

    def save_list(self):
        """Overwrite the client file with the current list."""
        with open(self.path, "w", newline="") as f:
            writer = csv.writer(f)
            for client in self.clients:
                writer.writerow(client.to_row())

    def add_client(self, client):
        """Add a new client, keep the list sorted, and save it."""
        self.clients.append(client)
        self.sort_list()
        self.save_list()

    def delete_client(self, client):
        """Delete a client and save the list. Returns True if they were found."""
        found, index = self.find(client)
        if not found:
            return False
        self.clients.pop(index)
        self.save_list()
        return True

    def sorted_by_score(self):
        """Return a copy of the list sorted by highest score (best first) using a bubble sort.

        It is a copy so the main list stays sorted by username for the binary search.
        Players with the same score stay in alphabetical order.
        """
        players = list(self.clients)
        for iteration in range(len(players) - 1, 0, -1):
            for index in range(iteration):
                if players[index].highest_score < players[index + 1].highest_score:
                    players[index], players[index + 1] = players[index + 1], players[index]
        return players

    def top_players(self, amount=5):
        """Return up to `amount` players with the best highest scores."""
        return self.sorted_by_score()[:amount]

    def ranked(self):
        """Return (rank, player) pairs, best first. Players with the same score share a rank."""
        rows = []
        for position, player in enumerate(self.sorted_by_score()):
            if rows and player.highest_score == rows[-1][1].highest_score:
                rank = rows[-1][0]
            else:
                rank = position + 1
            rows.append((rank, player))
        return rows

    def leaderboard(self, size=10, username=None):
        """The top `size` (rank, player) rows, plus the named player's row if they aren't in it."""
        rows = self.ranked()
        top = rows[:size]
        if username is not None and all(player.username != username for _, player in top):
            top += [row for row in rows[size:] if row[1].username == username]
        return top

    def update_player_in_list(self, player):
        """Save a player's latest score, and their highest score if they beat it.

        Returns False if the player isn't in the list.
        """
        found, index = self.find(player)
        if not found:
            return False
        stored = self.clients[index]
        stored.score = to_int(player.score)
        if stored.score > stored.highest_score:
            stored.highest_score = stored.score
        self.save_list()
        return True
