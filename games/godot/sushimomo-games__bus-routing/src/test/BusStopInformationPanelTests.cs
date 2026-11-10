using GdUnit4;
using Godot;
using System.Linq;
using static GdUnit4.Assertions;

[TestSuite]

public class BusStopInformationPanelTests
{
    // SCENARIO: There exist two bus stops and four houses. One bus stop is
    // accessible by two houses; a second bus stop is accessible by one house.
    // The fourth house cannot access any bus stop. When the player clicks
    // on the first bus stop, accessible to two houses, the information panel
    // will populate with the count of how many houses can access that stop.
    [TestCase]
    public void GivenHousesHaveDifferentBusStopAccess_WhenBusStopIsClicked_ThenInformationPanelShowsHouseCount()
    {

        // GIVEN: Two houses can access a single bus stop. Another house can access a
        // second bus stop. A fourth house cannot access any bus stop.
        var busStopScene = GD.Load<PackedScene>(Path.BusStopScene);
        var busStop = busStopScene.Instantiate<BusStop>();
        var otherBusStop = busStopScene.Instantiate<BusStop>();

        var accessibleHouseOne = new HouseWithReachableBusStop { AccessibleStop = busStop };
        var accessibleHouseTwo = new HouseWithReachableBusStop { AccessibleStop = busStop };
        var houseAtOtherStop = new HouseWithReachableBusStop { AccessibleStop = otherBusStop };
        var houseWithoutAccess = new HouseWithReachableBusStop { AccessibleStop = null };

        LevelState.AllHouses.Add(accessibleHouseOne);
        LevelState.AllHouses.Add(accessibleHouseTwo);
        LevelState.AllHouses.Add(houseAtOtherStop);
        LevelState.AllHouses.Add(houseWithoutAccess);

        var levelUIScene = GD.Load<PackedScene>("res://ui/level-ui/level-ui.tscn");
        var levelUI = levelUIScene.Instantiate<Control>();
        var infoPanel = levelUI.GetNode<InformationPanel>("InfoPanelContainer/informationPanel");
        LevelState.InformationPanel = infoPanel;
        infoPanel.Visible = false;

        // WHEN: The user clicks on the bus stop which is accessible by two houses.
        var click = new InputEventMouseButton
        {
            ButtonIndex = MouseButton.Left,
            Pressed = true
        };

        var busStopArea = busStop.GetNode<Area2D>("BusStopArea");
        busStopArea.EmitSignal(
            CollisionObject2D.SignalName.InputEvent,
            busStop,
            click,
            0L
        );

        // THEN: The information panel will be populated with the accurate
        // house count for that specific bus stop.
        var titleLabel = infoPanel.GetNode<Label>("VBoxContainer/TitleLabel");
        var infoLabel = infoPanel.GetNode<Label>("VBoxContainer/InfoText");

        AssertThat(infoPanel.Visible).IsTrue();
        AssertThat(titleLabel.Text).IsEqual("Bus Stop");
        AssertThat(infoLabel.Text).IsEqual("2 residents have access to this stop");

    }
}

public partial class HouseWithReachableBusStop : House
{
    public Node AccessibleStop { get; set; }

    public override Node ReachableBusStop => AccessibleStop;

}