using GdUnit4;
using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using static GdUnit4.Assertions;

[TestSuite]
public class HouseInformationPanelTests
{
    // SCENARIO: There is one possible route from a house to a destination
    // that a player can take. When the user clicks on the house, the information
    // panel will be populated with the commute details: probability percentage
    // and current itinerary.
    [TestCase]
    public void GivenHouseHasCommute_WhenHouseIsClicked_ThenInformationPanelShowsCommuteDetails()
    {

        // GIVEN: A house is near a bus stop with one route to a destination.
        var busStopScene = GD.Load<PackedScene>(Path.BusStopScene);
        var startStop = busStopScene.Instantiate<BusStop>();
        startStop.GlobalPosition = new Vector2(0, 0);
        var endStop = busStopScene.Instantiate<BusStop>();
        endStop.GlobalPosition = new Vector2(100, 0);

        var houseScene = GD.Load<PackedScene>(Path.HouseScene);
        var house = houseScene.Instantiate<House>();
        house.GlobalPosition = new Vector2(5, 0);
        house.BuildingColor = "Red";
        house.Modulate = Colors.Red;

        var destination = new DestinationStub(endStop)
        {
            GlobalPosition = new Vector2(105, 0),
            Modulate = Colors.Red
        };

        var validDestinations = new HashSet<Destination> { destination };

        var line = new BusLine
        {
            Path = [startStop, endStop]
        };
        LevelState.AllBusLines.Add(line);

        var route = Pathfinder.CalculateBestRoute(startStop, validDestinations);
        AssertObject(route).IsNotNull();
        route.Insert(0, new WalkSegment(house, startStop));
        var commute = new Commute(route);
        house.BusUsageProbability = 0.05f;

        var levelUiScene = GD.Load<PackedScene>("res://ui/level-ui/level-ui.tscn");
        var levelUi = levelUiScene.Instantiate<Control>();
        var infoPanel = levelUi.GetNode<InformationPanel>("InfoPanelContainer/informationPanel");
        LevelState.InformationPanel = infoPanel;
        infoPanel.Visible = false;

        var itineraryProperty = typeof(House).GetProperty(nameof(House.CurrentItinerary));
        var itinerarySetter = itineraryProperty?.GetSetMethod(nonPublic: true);
        AssertObject(itinerarySetter).IsNotNull();
        itinerarySetter.Invoke(house, new object[] { commute });

        // WHEN: The user left-clicks on the house.
        var click = new InputEventMouseButton
        {
            ButtonIndex = MouseButton.Left,
            Pressed = true
        };

        var houseArea = house.GetNode<Area2D>("Area2D");
        houseArea.EmitSignal(
            CollisionObject2D.SignalName.InputEvent,
            house,
            click,
            0L
        );

        // THEN: The information panel will be populated with the accurate
        // title label ([HouseColor] House) and info label (itinerary).
        var titleLabel = infoPanel.GetNode<Label>("VBoxContainer/TitleLabel");
        var infoLabel = infoPanel.GetNode<Label>("VBoxContainer/InfoText");
        var expectedInfo =
            $"Bus Usage Probability: {house.BusUsageProbability:P1}\n\n" +
            $"Itinerary:\nTotal Time: {commute.TotalTimeMinutes:F1} min\n" +
            string.Join("\n", commute.GetDirections());

        AssertThat(infoPanel.Visible).IsTrue();
        AssertThat(titleLabel.Text).IsEqual("Red House");
        AssertThat(infoLabel.Text).IsEqual(expectedInfo);


    }


}