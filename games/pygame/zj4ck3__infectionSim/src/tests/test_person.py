
import pytest
from person import Person

@pytest.fixture
def person():
    return Person("susceptible")


@pytest.mark.parametrize("status, expected_id, color", [
    ("susceptible", 1, (0, 0, 255)),
    ("infected", 2, (255, 0, 0)),
    ("carrier", 3, (255, 255, 0)),
    ("immune", 4, (0, 255, 0)),
    ("dead", 5, (64, 32, 0)),
    ("recovered", 6, (255, 0, 255)),
])
def test_change_status(person, status, expected_id, color):
    person.change_status(status)
    assert person.status == status
    assert person.id == expected_id
    assert person.color == color
    assert person.days_in_state == 0

def test_invalid_status(person):
    with pytest.raises(ValueError, match="invalid status"):
        person.change_status("invalid_status")

def test_dead_person_stays_dead(person):
    person.change_status("dead")
    neighbours = {"transmissible": 8, "untransmissible": 0}
    
    for i in range(10):
        result = person.calculate_change(neighbours, mortality=1.0)
        assert result == "dead"