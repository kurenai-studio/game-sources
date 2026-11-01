package dev.meowpow.boxbot.render.hud;

public enum HudPanels {
    STATUS_PANEL(0),
    ROBOT_PANEL(1),
    WAREHOUSE_PANEL(2),
    SHIPMENT_PANEL(3),
    ORDERS_PANEL(4);

    final int index;

    HudPanels(int index) {
        this.index = index;
    }
}
