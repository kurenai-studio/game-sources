package com.orangomango.minesweeper;

import javafx.application.Application;
import javafx.stage.Stage;
import javafx.scene.Scene;
import javafx.scene.layout.StackPane;
import javafx.scene.canvas.*;
import javafx.scene.paint.Color;
import javafx.animation.*;
import javafx.scene.input.MouseButton;
import javafx.scene.input.KeyCode;
import javafx.geometry.Point2D;

import java.util.HashMap;

public class MainApplication extends Application{
	private static final int WIDTH = 750;
	private static final int HEIGHT = 800;
	private static final int OFFSET_X = 50;
	private static final int OFFSET_Y = 130;

	private Map map;
	private boolean firstClick;
	private boolean showMines;
	private HashMap<KeyCode, Boolean> keys = new HashMap<>();
	private Display timer, mineCount;
	private volatile int timerCount = 0;
	private int totalMines;
	private boolean gameRunning = false;
	private double offsetX, offsetY, dragX = -1, dragY = -1;
	private int lastFlagX = -1, lastFlagY = -1;
	private Solver solver;

	private static volatile boolean THREAD_RUNNING = false;

	@Override
	public void start(Stage stage){
		StackPane pane = new StackPane();
		Canvas canvas = new Canvas(WIDTH, HEIGHT);
		GraphicsContext gc = canvas.getGraphicsContext2D();
		pane.getChildren().add(canvas);

		this.map = new Map(50, 50);
		this.timer = new Display(50, 20, 3, -1);
		this.mineCount = new Display(350, 20, 3, -1);

		this.solver = new Solver(this.map);

		Thread timerThread = new Thread(() -> {
			while (true){
				try {
					if (this.gameRunning){
						this.timer.update(this.timerCount);
						this.timerCount++;
						Thread.sleep(1000);
					} else {
						Thread.sleep(50);
					}
				} catch (InterruptedException ex){
					ex.printStackTrace();
				}
			}
		});
		timerThread.setDaemon(true);
		timerThread.start();

		canvas.setOnMousePressed(e -> {
			final int cellX = (int)((e.getX()-OFFSET_X-this.offsetX)/Cell.SIZE);
			final int cellY = (int)((e.getY()-OFFSET_Y-this.offsetY)/Cell.SIZE);
			Cell cell = this.map.getCellAt(cellX, cellY);

			if (!this.gameRunning && this.firstClick) return;

			if (cell != null){
				if (e.getButton() == MouseButton.PRIMARY){
					if (!this.firstClick){
						startGame(cellX, cellY);
					}

					if (cell.getRevealed() > 0){
						int flagCells = 0;
						for (int i = Math.max(cellX-1, 0); i < Math.min(cellX+2, this.map.getWidth()); i++){
							for (int j = Math.max(cellY-1, 0); j < Math.min(cellY+2, this.map.getHeight()); j++){
								Cell c = this.map.getCellAt(i, j);
								if (c.isFlag()){
									flagCells++;
								}
							}
						}

						if (flagCells == cell.getRevealed()){
							for (int i = Math.max(cellX-1, 0); i < Math.min(cellX+2, this.map.getWidth()); i++){
								for (int j = Math.max(cellY-1, 0); j < Math.min(cellY+2, this.map.getHeight()); j++){
									Cell c = this.map.getCellAt(i, j);
									if (!c.isFlag()){
										if (c.isMine()){
											gameOver();
										} else {
											c.reveal(this.map);
										}
									}
								}
							}
						}
					} else {
						if (cell.isFlag()){
							cell.toggleFlag();
							this.totalMines++;
							this.mineCount.update(this.totalMines);
						}
						boolean gameOver = cell.reveal(this.map);
						if (gameOver){
							cell.setGameOverCell();
							gameOver();
						}
					}				
				} else if (e.getButton() == MouseButton.SECONDARY){
					if (this.firstClick){
						if (cell.getRevealed() == -1){
							cell.toggleFlag();
							if (cell.isFlag()){
								this.totalMines--;
							} else {
								this.totalMines++;
							}
							this.mineCount.update(this.totalMines);

							this.lastFlagX = cellX;
							this.lastFlagY = cellY;
						}
					}
				}

				// Check if the game is finished
				if (this.map.isFinished()){
					gameWon();
				}
			}
		});

		canvas.setOnScroll(e -> {
			if (e.getDeltaY() > 0){
				Cell.SIZE += 2;
			} else if (e.getDeltaY() < 0){
				Cell.SIZE -= 2;
			}
		});

		canvas.setOnMouseDragged(e -> {
			if (e.getButton() == MouseButton.SECONDARY){
				if (this.dragX == -1 && this.dragY == -1){
					this.dragX = e.getX();
					this.dragY = e.getY();
				} else {
					this.offsetX += e.getX()-this.dragX;
					this.offsetY += e.getY()-this.dragY;
					this.dragX = e.getX();
					this.dragY = e.getY();
				}

				if (this.lastFlagX != -1 && this.lastFlagY != -1){ // Fix wrong flag while dragging
					Cell c = this.map.getCellAt(this.lastFlagX, this.lastFlagY);
					c.toggleFlag();
					if (c.isFlag()){
						this.totalMines--;
					} else {
						this.totalMines++;
					}
					this.mineCount.update(this.totalMines);
					this.lastFlagX = -1;
					this.lastFlagY = -1;
				}
			}
		});

		canvas.setOnMouseReleased(e -> {
			this.dragX = -1;
			this.dragY = -1;
			this.lastFlagX = -1;
			this.lastFlagY = -1;
		});

		canvas.setOnScroll(e -> {
			if (e.getDeltaY() > 0){
				Cell.SIZE += 2;
			} else if (e.getDeltaY() < 0){
				Cell.SIZE -= 2;
			}

			Cell.SIZE = Math.max(1, Math.min(100, Cell.SIZE));
		});

		canvas.setFocusTraversable(true);
		canvas.setOnKeyPressed(e -> this.keys.put(e.getCode(), true));
		canvas.setOnKeyReleased(e -> this.keys.put(e.getCode(), false));

		AnimationTimer loop = new AnimationTimer(){
			@Override
			public void handle(long time){
				update(gc);
			}
		};
		loop.start();

		Scene scene = new Scene(pane, WIDTH, HEIGHT);
		stage.setScene(scene);
		stage.setResizable(false);
		stage.setTitle("Minesweeper");
		stage.show();
	}

	private void gameOver(){
		System.out.println("GAME OVER");
		this.showMines = true;
		this.gameRunning = false;
	}

	private void gameWon(){
		System.out.println("YOU WIN");
		this.gameRunning = false;
	}

	private void startGame(int cellX, int cellY){
		int numMines = this.map.buildMines(cellX, cellY);
		this.totalMines = numMines;
		this.mineCount.update(this.totalMines);
		this.gameRunning = true;
		this.firstClick = true;
	}

	private void update(GraphicsContext gc){
		gc.clearRect(0, 0, WIDTH, HEIGHT);
		gc.setFill(Color.BLACK);
		gc.fillRect(0, 0, WIDTH, HEIGHT);

		if (this.keys.getOrDefault(KeyCode.F1, false)){
			this.showMines = !this.showMines;
			this.keys.put(KeyCode.F1, false);
		} else if (this.keys.getOrDefault(KeyCode.R, false)){
			this.map = new Map(this.map.getWidth(), this.map.getHeight());
			this.solver.setMap(this.map);
			this.firstClick = false;
			this.showMines = false;
			this.timer.update(-1);
			this.mineCount.update(-1);
			this.timerCount = 0;
			this.totalMines = 0;
			this.gameRunning = false;
			this.keys.put(KeyCode.R, false);
		} else if (this.keys.getOrDefault(KeyCode.SPACE, false)){
			if (THREAD_RUNNING){
				THREAD_RUNNING = false;
			} else {
				if (this.gameRunning || !this.firstClick){
					THREAD_RUNNING = true;
					new Thread(() -> {
						while (THREAD_RUNNING){
							try {
								System.out.println("Running Solver...");
								Point2D rnd = this.solver.solveStep(this.totalMines);
								if (rnd == null){
									THREAD_RUNNING = false;
								} else {
									if (rnd.getY() != -1){
										startGame((int)rnd.getX(), (int)rnd.getY());
										this.map.getCellAt((int)rnd.getX(), (int)rnd.getY()).reveal(this.map);
									} else {
										this.totalMines -= (int)rnd.getX();
										this.mineCount.update(this.totalMines);
									}

									if (this.map.isFinished()){
										gameWon();
										break;
									}
								}

								Thread.sleep(150);
							} catch (InterruptedException ex){
								ex.printStackTrace();
							}
						}
						System.out.println("Solver finished "+(this.map.isFinished() ? "(Game won)" : "(Need to guess)"));
					}).start();
				}
			}

			this.keys.put(KeyCode.SPACE, false);
		}

		gc.translate(OFFSET_X+this.offsetX, OFFSET_Y+this.offsetY);
		this.map.render(gc, this.showMines);
		gc.translate(-OFFSET_X-this.offsetX, -OFFSET_Y-this.offsetY);

		gc.setFill(Color.BLACK);
		gc.fillRect(0, 0, WIDTH, 120);
		this.timer.render(gc);
		this.mineCount.render(gc);
	}

	public static void main(String[] args){
		launch(args);
	}
}