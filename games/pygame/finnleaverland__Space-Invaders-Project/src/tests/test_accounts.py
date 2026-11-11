"""Tests for the account system: registering, logging in, password hashing, searching,
the leaderboard, and saving/loading the client file."""
import pytest

from space_invaders import accounts
from space_invaders.accounts import Client, ClientList, hash_secret, is_hashed, verify_secret


@pytest.fixture(autouse=True)
def fast_hashing(monkeypatch):
    """Use far fewer hash iterations so the tests run quickly."""
    monkeypatch.setattr(accounts, "HASH_ITERATIONS", 1_000)


@pytest.fixture
def accounts_file(tmp_path):
    """Path to a client file inside a temporary folder (not created yet)."""
    return tmp_path / "Clientfile.txt"


def write_lines(path, *lines):
    path.write_text("".join(line + "\n" for line in lines))


def make_list(accounts_file, *names):
    """A client list with the given usernames, each with password '<name>-pw'."""
    clients = ClientList(str(accounts_file))
    for name in names:
        clients.add_client(Client.new(name, f"{name}-pw", "Question?", "answer"))
    return clients


def usernames(clients):
    return [client.username for client in clients]


# --- Loading and saving --------------------------------------------------------

def test_missing_file_is_created_empty(accounts_file):
    clients = ClientList(str(accounts_file))
    assert accounts_file.exists()
    assert len(clients) == 0


def test_save_and_load_round_trip_keeps_every_field(accounts_file):
    clients = ClientList(str(accounts_file))
    zoe = Client.new("zoe", "secret", "First pet?", "Rex")
    zoe.score, zoe.highest_score = 40, 90
    clients.add_client(zoe)

    reloaded = ClientList(str(accounts_file))
    found, index = reloaded.find(Client("zoe"))
    assert found
    loaded = reloaded.clients[index]
    assert loaded.question == "First pet?"
    assert loaded.check_password("secret")
    assert loaded.check_answer("Rex")
    assert (loaded.score, loaded.highest_score) == (40, 90)


def test_loading_sorts_clients_by_username(accounts_file):
    scores_file(accounts_file, ("mike", 0), ("alice", 0), ("zoe", 0), ("bob", 0))
    clients = ClientList(str(accounts_file))
    assert usernames(clients.clients) == ["alice", "bob", "mike", "zoe"]


def test_loading_an_up_to_date_file_does_not_rewrite_it(accounts_file):
    make_list(accounts_file, "alice", "bob")
    before = accounts_file.read_text()
    ClientList(str(accounts_file))
    assert accounts_file.read_text() == before


# --- Old plain-text files ---------------------------------------------------------

def test_old_file_formats_still_load(accounts_file):
    write_lines(
        accounts_file,
        "carol, pw3, Town?, Leeds, 10, 300",  # old ", " separated style
        "dave,pw4,Colour?,red",               # no score columns
        "",                                   # blank line
        "broken,line",                        # too few fields
        "erin,pw5,Food?,pie,abc,",            # unreadable scores
    )
    clients = ClientList(str(accounts_file))
    assert usernames(clients.clients) == ["carol", "dave", "erin"]
    carol, dave, erin = clients.clients
    assert (carol.score, carol.highest_score) == (10, 300)
    assert (dave.score, dave.highest_score) == (0, 0)
    assert (erin.score, erin.highest_score) == (0, 0)


def test_old_plain_text_passwords_are_hashed_on_load(accounts_file):
    write_lines(accounts_file, "alice,pw1,Pet name?,Rex,0,50")

    clients = ClientList(str(accounts_file))
    alice = clients.clients[0]

    # the file no longer contains the plain-text password or answer
    saved = accounts_file.read_text()
    assert "pw1" not in saved and "Rex" not in saved
    assert "Pet name?" in saved
    assert is_hashed(alice.password_hash) and is_hashed(alice.answer_hash)

    # the player can still log in and reset their password as before
    reloaded = ClientList(str(accounts_file)).clients[0]
    assert reloaded.check_password("pw1")
    assert not reloaded.check_password("wrong")
    assert reloaded.check_answer("  rex ")
    assert reloaded.highest_score == 50


# --- Registering, logging in, resetting and deleting -------------------------------

def test_register_adds_client_in_sorted_position_and_saves(accounts_file):
    clients = make_list(accounts_file, "alice", "zoe")
    clients.add_client(Client.new("mike", "pw", "Q?", "A"))

    assert usernames(clients.clients) == ["alice", "mike", "zoe"]
    assert usernames(ClientList(str(accounts_file)).clients) == ["alice", "mike", "zoe"]


def test_passwords_are_never_saved_as_plain_text(accounts_file):
    make_list(accounts_file, "alice")
    saved = accounts_file.read_text()
    assert "alice-pw" not in saved
    assert "answer" not in saved


def test_same_password_gets_a_different_salted_hash(accounts_file):
    clients = ClientList(str(accounts_file))
    clients.add_client(Client.new("alice", "same", "Q?", "A"))
    clients.add_client(Client.new("bob", "same", "Q?", "A"))
    alice, bob = clients.clients
    assert alice.password_hash != bob.password_hash
    assert alice.check_password("same") and bob.check_password("same")


def test_login_checks_the_password(accounts_file):
    clients = make_list(accounts_file, "alice", "bob")
    found, index = clients.find(Client("bob"))
    assert found
    bob = clients.clients[index]
    assert bob.check_password("bob-pw")
    assert not bob.check_password("wrong")
    assert not bob.check_password("BOB-PW")
    assert not bob.check_password("")


def test_login_with_unknown_username_is_not_found(accounts_file):
    clients = make_list(accounts_file, "alice", "bob")
    assert clients.find(Client("nobody")) == (False, -1)


def test_security_answer_ignores_case_and_spaces():
    client = Client.new("alice", "pw", "Pet name?", "Rex")
    assert client.check_answer("rex")
    assert client.check_answer("  REX  ")
    assert not client.check_answer("Max")


def test_reset_password(accounts_file):
    clients = make_list(accounts_file, "alice")
    alice = clients.clients[0]
    alice.set_password("new-pw")
    clients.save_list()

    reloaded = ClientList(str(accounts_file)).clients[0]
    assert reloaded.check_password("new-pw")
    assert not reloaded.check_password("alice-pw")


def test_delete_client(accounts_file):
    clients = make_list(accounts_file, "alice", "bob", "carol")
    assert clients.delete_client(Client("bob"))
    assert not clients.delete_client(Client("bob"))
    assert usernames(ClientList(str(accounts_file)).clients) == ["alice", "carol"]


# --- Hash format ------------------------------------------------------------------

def test_hash_format_records_algorithm_iterations_and_salt():
    name, iterations, salt, digest = hash_secret("pw").split("$")
    assert name == "pbkdf2_sha256"
    assert int(iterations) == accounts.HASH_ITERATIONS
    assert len(bytes.fromhex(salt)) == accounts.SALT_BYTES
    assert len(bytes.fromhex(digest)) == 32  # SHA-256


def test_hashes_still_verify_after_iteration_count_changes(monkeypatch):
    stored = hash_secret("pw")
    monkeypatch.setattr(accounts, "HASH_ITERATIONS", 2_000)
    assert verify_secret("pw", stored)


@pytest.mark.parametrize("value", ["", "pw1", "pbkdf2_sha256$abc$00$00", "md5$1000$00$00",
                                   "pbkdf2_sha256$1000$zz$00", "pbkdf2_sha256$1000$00"])
def test_values_that_are_not_hashes(value):
    assert not is_hashed(value)
    assert not verify_secret("pw1", value)


# --- Recursive binary search -----------------------------------------------------

NAMES = ["alice", "bob", "carol", "dave", "erin", "frank", "gina"]


@pytest.mark.parametrize("size", range(1, len(NAMES) + 1))
def test_binary_search_finds_every_client(accounts_file, size):
    clients = make_list(accounts_file, *NAMES[:size])
    for expected_index, name in enumerate(NAMES[:size]):
        assert clients.find(Client(name)) == (True, expected_index)


@pytest.mark.parametrize("missing", ["aaron", "bobby", "zed", "", "Alice"])
def test_binary_search_reports_missing_clients(accounts_file, missing):
    clients = make_list(accounts_file, *NAMES)
    assert clients.find(Client(missing)) == (False, -1)


def test_binary_search_on_empty_list(accounts_file):
    clients = ClientList(str(accounts_file))
    assert clients.find(Client("alice")) == (False, -1)


# --- Leaderboard -----------------------------------------------------------------

def scores_file(path, *rows):
    """Write a client file of (username, highest score) rows."""
    write_lines(path, *(f"{name},{hash_secret('pw')},Q?,{hash_secret('a')},0,{best}" for name, best in rows))


def test_leaderboard_is_ordered_by_highest_score(accounts_file):
    scores_file(accounts_file, ("alice", 50), ("bob", 300), ("carol", 10), ("dave", 120))
    clients = ClientList(str(accounts_file))
    assert usernames(clients.sorted_by_score()) == ["bob", "dave", "alice", "carol"]
    # the main list must stay sorted by username so the binary search keeps working
    assert usernames(clients.clients) == ["alice", "bob", "carol", "dave"]


def test_leaderboard_ties_keep_alphabetical_order(accounts_file):
    scores_file(accounts_file, ("zoe", 100), ("amy", 100), ("max", 200))
    board = ClientList(str(accounts_file)).sorted_by_score()
    assert usernames(board) == ["max", "amy", "zoe"]


def test_top_players_returns_at_most_five(accounts_file):
    scores_file(accounts_file, *((f"p{i}", i * 10) for i in range(8)))
    top = ClientList(str(accounts_file)).top_players(5)
    assert usernames(top) == ["p7", "p6", "p5", "p4", "p3"]


def test_new_score_only_replaces_highest_score_when_better(accounts_file):
    scores_file(accounts_file, ("alice", 100))
    clients = ClientList(str(accounts_file))

    clients.update_player_in_list(Client("alice", score=60))
    alice = ClientList(str(accounts_file)).clients[0]
    assert (alice.score, alice.highest_score) == (60, 100)

    clients.update_player_in_list(Client("alice", score=250))
    alice = ClientList(str(accounts_file)).clients[0]
    assert (alice.score, alice.highest_score) == (250, 250)


def test_updating_unknown_player_does_nothing(accounts_file):
    clients = make_list(accounts_file, "alice")
    assert not clients.update_player_in_list(Client("nobody", score=999))


def test_ranks_are_shared_by_equal_scores(accounts_file):
    scores_file(accounts_file, ("amy", 100), ("bob", 300), ("cat", 300), ("dan", 50))
    ranked = [(rank, player.username) for rank, player in ClientList(str(accounts_file)).ranked()]
    assert ranked == [(1, "bob"), (1, "cat"), (3, "amy"), (4, "dan")]


def test_leaderboard_adds_the_players_own_row_when_outside_the_top(accounts_file):
    scores_file(accounts_file, *((f"p{i}", i * 10) for i in range(12)))
    board = ClientList(str(accounts_file)).leaderboard(size=10, username="p0")
    assert [player.username for _, player in board] == [f"p{i}" for i in range(11, 1, -1)] + ["p0"]
    assert board[-1][0] == 12


def test_leaderboard_does_not_repeat_a_player_already_in_the_top(accounts_file):
    scores_file(accounts_file, ("amy", 100), ("bob", 300))
    board = ClientList(str(accounts_file)).leaderboard(size=10, username="bob")
    assert [player.username for _, player in board] == ["bob", "amy"]
