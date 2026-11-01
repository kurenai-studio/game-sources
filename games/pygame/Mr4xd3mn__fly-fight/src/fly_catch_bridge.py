"""Launch the desktop fly fight game with the connectome controller."""

from catch_game import play_test


if __name__ == "__main__":
    import os

    print("Log file:", os.environ.get(
        "FLY_BRAIN_LOG", "brain_logs\\brain_session_<timestamp>.jsonl"
    ), flush=True)
    play_test(use_brain=True)
