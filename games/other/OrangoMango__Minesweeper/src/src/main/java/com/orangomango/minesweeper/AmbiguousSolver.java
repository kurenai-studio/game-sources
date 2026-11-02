package com.orangomango.minesweeper;

import javafx.geometry.Point2D;

import java.util.ArrayList;

public class AmbiguousSolver{
	// 0-8 reveal
	// -1 not revealed
	// -2 flag
	// -3 to reveal
	private int[][] world;

	public AmbiguousSolver(Map map){
		this.world = new int[map.getWidth()][map.getHeight()];

		for (int i = 0; i < map.getWidth(); i++){
			for (int j = 0; j < map.getHeight(); j++){
				Cell cell = map.getCellAt(i, j);
				if (cell.isFlag()){
					this.world[i][j] = -2;
				} else {
					this.world[i][j] = cell.getRevealed();
				}
			}
		}
	}

	public int apply(Map map){
		int count = 0;

		for (int i = 0; i < map.getWidth(); i++){
			for (int j = 0; j < map.getHeight(); j++){
				if (this.world[i][j] == -2 && !map.getCellAt(i, j).isFlag()){
					map.getCellAt(i, j).toggleFlag();
					count++;
				} else if (this.world[i][j] == -3){
					map.getCellAt(i, j).reveal(map);
				}
			}
		}

		return count;
	}

	public boolean solve(int minesAvailable){
		ArrayList<Point2D> availableCells = new ArrayList<>();
		ArrayList<Point2D> possibilities = new ArrayList<>();
		ArrayList<int[][]> maps = new ArrayList<>();
		ArrayList<ArrayList<Point2D>> groups = new ArrayList<>();

		int[][] flagMap = new int[this.world.length][this.world[0].length];

		for (int x = 0; x < this.world.length; x++){
			for (int y = 0; y < this.world[0].length; y++){
				int num = this.world[x][y];
				if (num > 0 && hasEmpty(x, y)){
					availableCells.add(new Point2D(x, y));
				}
			}
		}

		// Build current flags map
		for (Point2D p : availableCells){
			flagMap[(int)p.getX()][(int)p.getY()] = countFlags(this.world, (int)p.getX(), (int)p.getY());
		}

		for (int i = 0; i < availableCells.size(); i++){
			ArrayList<Point2D> neighbors = getNeighbors(this.world, (int)availableCells.get(i).getX(), (int)availableCells.get(i).getY());
			for (Point2D n : neighbors){
				if (!possibilities.contains(n)){
					possibilities.add(n);
				}
			}
		}

		// Divide possibilities into groups
		ArrayList<Point2D> currentList = new ArrayList<>();
		currentList.add(possibilities.remove(0));
		while (possibilities.size() > 0){
			// Search a cell of distance 1
			Point2D found = null;
			poss_loop:
			for (Point2D p : possibilities){
				for (Point2D someElement : currentList){
					if (Math.abs(p.getX()-someElement.getX()) <= 2 && Math.abs(p.getY()-someElement.getY()) <= 2){
						found = p;
						break poss_loop;
					}
				}
			}

			if (found != null){
				currentList.add(found);
				possibilities.remove(found);
			} else {
				groups.add(currentList);
				currentList = new ArrayList<>();
				currentList.add(possibilities.remove(0));
			}
		}

		groups.add(currentList);
		groups.sort((g1, g2) -> Integer.compare(g1.size(), g2.size()));

		System.out.println("groups: "+groups+", "+groups.size());

		boolean actionPerformed = false;
		while (groups.size() > 0 && !actionPerformed){
			ArrayList<Point2D> poss = groups.remove(0); // Smallest group
			System.out.println("poss: "+poss+", "+poss.size());
			ArrayList<Point2D> neighborCells = getValidAvailableCells(poss, availableCells);

			walk(poss, neighborCells, 0, maps, minesAvailable, flagMap);

			double[] count = calculateProb(poss, maps);
			for (int i = 0; i < count.length; i++){
				Point2D p = poss.get(i);
				if (count[i] == 1){
					this.world[(int)p.getX()][(int)p.getY()] = -2;
					actionPerformed = true;
				} else if (count[i] == 0){
					this.world[(int)p.getX()][(int)p.getY()] = -3;
					actionPerformed = true;
				}
			}

			// DEBUG
			System.out.println(java.util.Arrays.toString(count));
		}

		return actionPerformed;
	}

	private static ArrayList<Point2D> getValidAvailableCells(ArrayList<Point2D> possibilities, ArrayList<Point2D> availableCells){
		ArrayList<Point2D> output = new ArrayList<>();

		for (Point2D a : availableCells){
			for (Point2D b : possibilities){
				if (Math.abs(a.getX()-b.getX()) <= 1 && Math.abs(a.getY()-b.getY()) <= 1){
					output.add(a);
					break;
				}
			}
		}

		return output;
	}

	private static ArrayList<Point2D> getNeighbors(int[][] world, int x, int y){
		ArrayList<Point2D> output = new ArrayList<>();
		for (int i = Math.max(0, x-1); i < Math.min(world.length, x+2); i++){
			for (int j = Math.max(0, y-1); j < Math.min(world[0].length, y+2); j++){
				int num = world[i][j];
				if (num == -1){
					output.add(new Point2D(i, j));
				}
			}
		}

		return output;
	}

	private static double[] calculateProb(ArrayList<Point2D> possibilities, ArrayList<int[][]> maps){
		double[] count = new double[possibilities.size()];
		for (int i = 0; i < maps.size(); i++){
			int[][] map = maps.get(i);

			for (int j = 0; j < possibilities.size(); j++){
				Point2D p = possibilities.get(j);
				if (map[(int)p.getX()][(int)p.getY()] == -2){
					count[j]++;
				}
			}
		}

		for (int i = 0; i < count.length; i++){
			count[i] /= maps.size();
		}

		return count;
	}

	private void walk(ArrayList<Point2D> list, ArrayList<Point2D> availableCells, int index, ArrayList<int[][]> output, int minesAvailable, int[][] flagMap){
		if (index == list.size()){
			int[][] backup = backup();

			boolean valid = true;
			for (int i = 0; i < availableCells.size(); i++){
				Point2D p = availableCells.get(i);
				if (backup[(int)p.getX()][(int)p.getY()] != flagMap[(int)p.getX()][(int)p.getY()]){
					valid = false;
					break;
				}
			}

			if (valid){
				output.add(backup);
			}

			return;
		}

		Point2D pos = list.get(index);

		// Try to use this flag
		if (minesAvailable > 0 && isValid(this.world, flagMap, (int)pos.getX(), (int)pos.getY())){
			this.world[(int)pos.getX()][(int)pos.getY()] = -2;
			updateFlagMap(flagMap, (int)pos.getX(), (int)pos.getY(), 1);

			walk(list, availableCells, index+1, output, minesAvailable-1, flagMap);

			this.world[(int)pos.getX()][(int)pos.getY()] = -1;
			updateFlagMap(flagMap, (int)pos.getX(), (int)pos.getY(), -1);
		}

		// Try to not use this flag
		if (isEmptyValid(world, flagMap, (int)pos.getX(), (int)pos.getY(), list, index+1)){
			walk(list, availableCells, index+1, output, minesAvailable, flagMap);
		}
	}

	private int[][] backup(){
		int[][] output = new int[this.world.length][this.world[0].length];

		for (int x = 0; x < this.world.length; x++){
			for (int y = 0; y < this.world[0].length; y++){
				output[x][y] = this.world[x][y];
			}
		}

		return output;
	}

	private static boolean isEmptyValid(int[][] world, int[][] flagMap, int x, int y, ArrayList<Point2D> list, int index){
		// Get all possible neighbors
		ArrayList<Point2D> neighbors = new ArrayList<>();
		for (int i = Math.max(0, x-1); i < Math.min(world.length, x+2); i++){
			for (int j = Math.max(0, y-1); j < Math.min(world[0].length, y+2); j++){
				int num = world[i][j];
				if (num > 0){
					neighbors.add(new Point2D(i, j));
				}
			}
		}

		// Filter the 'last-tile' ones
		ArrayList<Point2D> lastOnes = new ArrayList<>();
		for (Point2D p : neighbors){
			if (index == list.size()){
				lastOnes.add(p);
			} else {
				ArrayList<Point2D> subList = new ArrayList<>(list.subList(index, list.size()));
				boolean contained = false;
				final int px = (int)p.getX();
				final int py = (int)p.getY();
				x_loop:
				for (int i = Math.max(0, px-1); i < Math.min(world.length, px+2); i++){
					for (int j = Math.max(0, py-1); j < Math.min(world[0].length, py+2); j++){
						if (subList.contains(new Point2D(i, j))){
							contained = true;
							break x_loop;
						}
					}
				}

				if (!contained){
					lastOnes.add(p);
				}
			}
		}

		// Check if the 'last-tiles' are valid
		for (Point2D p : lastOnes){
			if (world[(int)p.getX()][(int)p.getY()] != flagMap[(int)p.getX()][(int)p.getY()]){
				return false;
			}
		}

		return true;
	}

	private static void updateFlagMap(int[][] flagMap, int x, int y, int inc){
		for (int i = Math.max(0, x-1); i < Math.min(flagMap.length, x+2); i++){
			for (int j = Math.max(0, y-1); j < Math.min(flagMap[0].length, y+2); j++){
				flagMap[i][j] += inc; // Ignore -1 tiles
			}
		}
	}

	private static boolean isValid(int[][] world, int[][] flagMap, int x, int y){
		for (int i = Math.max(0, x-1); i < Math.min(world.length, x+2); i++){
			for (int j = Math.max(0, y-1); j < Math.min(world[0].length, y+2); j++){
				int num = world[i][j];
				if (num > 0){
					if (flagMap[i][j]+1 > num){
						return false;
					}
				}
			}
		}

		return true;
	}

	private static int countFlags(int[][] world, int x, int y){
		int count = 0;
		for (int i = Math.max(0, x-1); i < Math.min(world.length, x+2); i++){
			for (int j = Math.max(0, y-1); j < Math.min(world[0].length, y+2); j++){
				int num = world[i][j];
				if (num == -2){
					count++;
				}
			}
		}

		return count;
	}

	private boolean hasEmpty(int x, int y){
		for (int i = Math.max(0, x-1); i < Math.min(this.world.length, x+2); i++){
			for (int j = Math.max(0, y-1); j < Math.min(this.world[0].length, y+2); j++){
				int num = this.world[i][j];
				if (num == -1){
					return true;
				}
			}
		}

		return false;
	}
}