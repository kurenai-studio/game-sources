package com.mygdx.fourcats;

import com.mygdx.fourcats.events.EventBroker;
import com.mygdx.fourcats.events.MouseCaughtEvent;
import com.mygdx.fourcats.managers.CatManager;
import com.mygdx.fourcats.managers.SimpleMouseManager;

import java.util.ArrayList;
import java.util.List;

public class MouseCaughtChecker
{
    CatManager observedCatManager;

    SimpleMouseManager observedMouseManager;

    int CATSIZE = Config.CAT_SIZE;

    int MOUSESIZE = Config.MOUSE_SIZE;

    public MouseCaughtChecker(CatManager catManager, SimpleMouseManager mouseManager)
    {
        observedCatManager = catManager;

        observedMouseManager = mouseManager;
    }

    public void check()
    {
        Position CatPosition = observedCatManager.getCatPositon();
        List<Position> MicePositions = observedMouseManager.getPositionList();

        ArrayList<Integer> caughtMiceIndices = new ArrayList<>();

        for (int index = 0; index < MicePositions.size(); index ++ )
        {
            if (isWithinTolerance(CatPosition.X,
                    MicePositions.get(index).X,
                    CatPosition.Y,
                    MicePositions.get(index).Y))
            {
                caughtMiceIndices.add(index);
            }
        }

        for (int i = caughtMiceIndices.size() - 1; i >= 0; i --)
        {
            int mouseIndex = caughtMiceIndices.get(i);
            EventBroker.getInstance().transmitMouseCaught(
                    new MouseCaughtEvent(mouseIndex, MicePositions.get(mouseIndex).X, MicePositions.get(mouseIndex).Y)
            );
        }
    }

    private boolean isWithinTolerance(int ax, int bx, int ay, int by)
    {
        return Math.abs(ax + (CATSIZE/2) - (bx + (MOUSESIZE / 2)) ) <= (CATSIZE / 2 ) && Math.abs(ay + (CATSIZE/2) - (by + (MOUSESIZE / 2)) ) <= (CATSIZE / 2 );
    }
}
