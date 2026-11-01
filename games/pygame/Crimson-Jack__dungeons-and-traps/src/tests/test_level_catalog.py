from pathlib import Path

import pytest

from src.level_catalog import LEVELS

# Built from the test file location, so the check does not depend on the working directory
TMX_DIRECTORY = Path(__file__).resolve().parents[1] / 'data' / 'tmx'


class TestLevelCatalog:
    def test_every_level_has_secret_code(self):
        assert all(level_details.secret_code for level_details in LEVELS)

    def test_secret_codes_are_unique(self):
        secret_codes = [level_details.secret_code for level_details in LEVELS]

        assert len(secret_codes) == len(set(secret_codes))

    def test_only_last_campaign_level_is_final(self):
        final_level_filenames = [level_details.source_file for level_details in LEVELS if level_details.is_final_level]

        assert final_level_filenames == ['s01_level_09.tmx']

    @pytest.mark.parametrize('level_details', LEVELS, ids=lambda level_details: level_details.source_file)
    def test_tmx_file_exists(self, level_details):
        assert (TMX_DIRECTORY / level_details.source_file).is_file()
