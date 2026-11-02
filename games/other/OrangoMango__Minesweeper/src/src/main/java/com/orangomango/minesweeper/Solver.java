package com.orangomango.minesweeper;

import javafx.geometry.Point2D;
import javafx.util.Pair;

import java.util.Random;
import java.util.ArrayList;

public class Solver{
	private Map map;

	public Solver(Map map){
		this.map = map;
	}

	public void setMap(Map map){
		this.map = map;
	}

	public Point2D solveStep(int minesAvailable){
		int count = 0;
		boolean actionPerformed = false;
		int flagsRaised = 0;

		for (int i = 0; i < this.map.getWidth(); i++){
			for (int j = 0; j < this.map.getHeight(); j++){
				Cell cell = this.map.getCellAt(i, j);
				if (cell.getRevealed() > 0){
					Pair<ArrayList<Point2D>, Integer> info = getInfo(i, j);

					if (info.getKey().size() == cell.getRevealed()-info.getValue()){
						for (Point2D p : info.getKey()){
							this.map.getCellAt((int)p.getX(), (int)p.getY()).toggleFlag();
							flagsRaised++;
						}
						if (info.getKey().size() > 0) actionPerformed = true;
					} else if (cell.getRevealed() == info.getValue()){
						for (Point2D p : info.getKey()){
							this.map.getCellAt((int)p.getX(), (int)p.getY()).reveal(this.map);
						}
						actionPerformed = true;
					}

					count++;
				}
			}
		}

		if (count == 0){
			Random random = new Random();
			int rx = random.nextInt(this.map.getWidth());
			int ry = random.nextInt(this.map.getHeight());
			return new Point2D(rx, ry);
		}

		if (!actionPerformed){
			if (minesAvailable == 0){
				for (int i = 0; i < this.map.getWidth(); i++){
					for (int j = 0; j < this.map.getHeight(); j++){
						Cell cell = this.map.getCellAt(i, j);
						if (cell.getRevealed() == -1){
							cell.reveal(this.map);
						}
					}
				}
			} else {
				System.out.println("Running AmbiguousSolver...");
				AmbiguousSolver solver = new AmbiguousSolver(this.map);
				boolean as = solver.solve(minesAvailable);

				flagsRaised = solver.apply(this.map);

				if (!as) return null;
			}
		}

		return new Point2D(flagsRaised, -1); // Small hack :)
	}

	private Pair<ArrayList<Point2D>, Integer> getInfo(int x, int y){
		Cell cell = this.map.getCellAt(x, y);
		int neighbors = 0;
		ArrayList<Point2D> free = new ArrayList<>();

		for (int i = Math.max(x-1, 0); i < Math.min(x+2, this.map.getWidth()); i++){
			for (int j = Math.max(y-1, 0); j < Math.min(y+2, this.map.getHeight()); j++){
				Cell c = this.map.getCellAt(i, j);
				if (c.isFlag()){
					neighbors++;
				} else if (c.getRevealed() == -1){
					free.add(new Point2D(i, j));
				}
			}
		}

		return new Pair<ArrayList<Point2D>, Integer>(free, neighbors);
	}
}