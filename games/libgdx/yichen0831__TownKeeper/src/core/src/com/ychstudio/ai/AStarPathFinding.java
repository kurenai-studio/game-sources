package com.ychstudio.ai;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.Fixture;
import com.badlogic.gdx.physics.box2d.QueryCallback;
import com.badlogic.gdx.physics.box2d.World;
import com.ychstudio.gamesys.GameManager;

public class AStarPathFinding {

    static final int WALKABLE = 0;
    static final int SOURCE = 1;
    static final int TARGET = 2;
    static final int NON_WALKABLE = 3;
    static final int PATH = 4;

    // 0: walkable, 1: source, 2: target, 3: not walkable, 4: path

    int[][] map; // indication map

    Node[][] nodeMap;

    private boolean isWall;

    private int mapWidth;
    private int mapHeight;

    private AStarPathFinding() {
    }

    private static final AStarPathFinding instance = new AStarPathFinding(); // singleton

    public static AStarPathFinding getInstance() {
        return instance;
    }

    /**
     * Initialize the map info of A* path finding, only need to be called once
     * the world is created
     * 
     * @param world
     *            the Box2D world
     * @param mapWidth
     *            the map width
     * @param mapHeight
     *            the map height
     */
    public void init(World world, int mapWidth, int mapHeight) {
        this.mapWidth = mapWidth;
        this.mapHeight = mapHeight;

        map = new int[mapHeight][mapWidth];

        for (int y = 0; y < mapHeight; y++) {
            for (int x = 0; x < mapWidth; x++) {
                isWall = false;
                world.QueryAABB(queryCallback, x + 0.2f, y + 0.2f, x + 0.8f, y + 0.8f);
                if (isWall) {
                    map[y][x] = NON_WALKABLE;
                }
            }
        }
    }

    /**
     * find path that allows diagonal walk
     * 
     * @param source
     *            the origin
     * @param target
     *            the destination
     * @return the node to start walking (the source's next node)
     */
    public Node findPath(Vector2 source, Vector2 target) {

        nodeMap = new Node[mapHeight][mapWidth];

        List<Node> openNodes = new ArrayList<>();

        int sX = (int) source.x;
        int sY = (int) source.y;
        int tX = (int) target.x;
        int tY = (int) target.y;

        Node targetNode = new Node(tX, tY);
        Node sourceNode = new Node(sX, sY);

        nodeMap[sY][sX] = sourceNode;
        nodeMap[tY][tX] = targetNode;

        openNodes.add(sourceNode);

        boolean targetReached = false;

        while (!openNodes.isEmpty()) {

            // sort to find the node with lowest fCost
            openNodes.sort(new Comparator<Node>() {
                @Override
                public int compare(Node n1, Node n2) {
                    return n1.fCost() - n2.fCost();
                }
            });

            Node evaluatingNode = openNodes.get(0);

            // check neighbor nodes
            for (int y = -1; y <= 1; y++) {
                for (int x = -1; x <= 1; x++) {
                    if (x == 0 && y == 0) {
                        // no need to evaluate the node itself
                        continue;
                    }

                    int neighborX = evaluatingNode.x + x;
                    int neighborY = evaluatingNode.y + y;

                    if (outOfMap(neighborX, neighborY)) {
                        continue;
                    }

                    if (map[neighborY][neighborX] == NON_WALKABLE) {
                        continue;
                    } else {
                        Node neighborNode = nodeMap[neighborY][neighborX];

                        if (neighborNode == targetNode) {
                            targetNode.prevNode = evaluatingNode;
                            targetReached = true;
                            break;
                        } else if (neighborNode == null) {
                            neighborNode = new Node(neighborX, neighborY);
                            neighborNode.gCost = evaluatingNode.gCost + (Math.abs(x) + Math.abs(y) > 1 ? 14 : 10);

                            int xDist = Math.abs(tX - neighborX);
                            int yDist = Math.abs(tY - neighborY);

                            neighborNode.hCost = (Math.max(xDist, yDist) - Math.min(xDist, yDist)) * 10
                                    + Math.min(xDist, yDist) * 14;

                            neighborNode.prevNode = evaluatingNode;
                            nodeMap[neighborY][neighborX] = neighborNode;
                            openNodes.add(neighborNode);
                        } else {

                            if (neighborNode.closed) {
                                continue;
                            }
                            // re-calculate gCost
                            if (neighborNode.gCost > evaluatingNode.gCost + (Math.abs(x) + Math.abs(y) > 1 ? 14 : 10)) {
                                neighborNode.gCost = evaluatingNode.gCost + (Math.abs(x) + Math.abs(y) > 1 ? 14 : 10);
                                neighborNode.prevNode = evaluatingNode;
                            }
                        }
                    }

                }
                if (targetReached) {
                    break;
                }
            }

            evaluatingNode.closed = true;
            openNodes.remove(evaluatingNode);

            if (targetReached) {
                // openNodes.clear();
                break;
            }

        }

        if (!targetReached) {
            // cannot find path
            return null;
        }

        // trace to the first node (source node)
        Node node = targetNode;
        while (node.prevNode != null)

        {
            node.prevNode.nextNode = node;
            node = node.prevNode;
        }

        // return source' next node
        return node.nextNode;
    }

    /**
     * find path without diagonal walking
     * 
     * @param source
     *            the origin
     * @param target
     *            the destination
     * @return the node to start walking (the source's next node)
     */
    public Node findPathOrtho(Vector2 source, Vector2 target) {

        nodeMap = new Node[mapHeight][mapWidth];

        List<Node> openNodes = new ArrayList<>();

        int sX = (int) source.x;
        int sY = (int) source.y;
        int tX = (int) target.x;
        int tY = (int) target.y;

        Node targetNode = new Node(tX, tY);
        Node sourceNode = new Node(sX, sY);

        nodeMap[sY][sX] = sourceNode;
        nodeMap[tY][tX] = targetNode;

        openNodes.add(sourceNode);

        boolean targetReached = false;

        while (!openNodes.isEmpty()) {

            // sort to find the node with lowest fCost
            openNodes.sort(new Comparator<Node>() {
                @Override
                public int compare(Node n1, Node n2) {
                    return n1.fCost() - n2.fCost();
                }
            });

            Node evaluatingNode = openNodes.get(0);

            // check horizontal neighbor nodes
            for (int x = -1; x <= 1; x++) {
                if (x == 0) {
                    // no need to evaluate the node itself
                    continue;
                }

                int neighborX = evaluatingNode.x + x;
                int neighborY = evaluatingNode.y;

                if (outOfMap(neighborX, neighborY)) {
                    continue;
                }

                if (map[neighborY][neighborX] == NON_WALKABLE) {
                    continue;
                } else {
                    Node neighborNode = nodeMap[neighborY][neighborX];

                    if (neighborNode == targetNode) {
                        targetNode.prevNode = evaluatingNode;
                        targetReached = true;
                    } else if (neighborNode == null) {
                        neighborNode = new Node(neighborX, neighborY);
                        neighborNode.gCost = evaluatingNode.gCost + 10;
                        neighborNode.hCost = (Math.abs(tX - neighborX) + Math.abs(tY - neighborY)) * 10;
                        neighborNode.prevNode = evaluatingNode;
                        nodeMap[neighborY][neighborX] = neighborNode;
                        openNodes.add(neighborNode);
                    } else {

                        if (neighborNode.closed) {
                            continue;
                        }
                        // re-calculate gCost
                        if (neighborNode.gCost > evaluatingNode.gCost + 10) {
                            neighborNode.gCost = evaluatingNode.gCost + 10;
                            neighborNode.prevNode = evaluatingNode;
                        }
                    }
                }
            }

            // check vertical neighbor nodes
            if (!targetReached) {
                for (int y = -1; y <= 1; y++) {
                    if (y == 0) {
                        // no need to evaluate the node itself
                        continue;
                    }

                    int neighborX = evaluatingNode.x;
                    int neighborY = evaluatingNode.y + y;

                    if (outOfMap(neighborX, neighborY)) {
                        continue;
                    }

                    if (map[neighborY][neighborX] == NON_WALKABLE) {
                        continue;
                    } else {
                        Node neighborNode = nodeMap[neighborY][neighborX];

                        if (neighborNode == targetNode) {
                            targetNode.prevNode = evaluatingNode;
                            targetReached = true;
                        } else if (neighborNode == null) {
                            neighborNode = new Node(neighborX, neighborY);
                            neighborNode.gCost = evaluatingNode.gCost + 10;
                            neighborNode.hCost = (Math.abs(tX - neighborX) + Math.abs(tY - neighborY)) * 10;
                            neighborNode.prevNode = evaluatingNode;
                            nodeMap[neighborY][neighborX] = neighborNode;
                            openNodes.add(neighborNode);
                        } else {
                            if (neighborNode.closed) {
                                continue;
                            }
                            // re-calculate gCost
                            if (neighborNode.gCost > evaluatingNode.gCost + 10) {
                                neighborNode.gCost = evaluatingNode.gCost + 10;
                                neighborNode.prevNode = evaluatingNode;
                            }
                        }
                    }
                }
            }

            evaluatingNode.closed = true;
            openNodes.remove(evaluatingNode);

            if (targetReached) {
                // openNodes.clear();
                break;
            }
        }

        if (!targetReached)

        {
            // cannot find a path
            return null;
        }

        // trace to the first node (source node)
        Node node = targetNode;
        while (node.prevNode != null)

        {
            node.prevNode.nextNode = node;
            node = node.prevNode;
        }

        // return source' next node
        return node.nextNode;

    }

    private boolean outOfMap(int x, int y) {
        return x < 0 || x >= mapWidth || y < 0 || y >= mapHeight;
    }

    public boolean isWalkableAt(int x, int y) {
        return map[y][x] != NON_WALKABLE;
    }

    public boolean isWalkableAt(Vector2 pos) {
        return map[(int) pos.y][(int) pos.x] != NON_WALKABLE;
    }

    protected void printResult(int map[][], Node source) { // for debug

        Node node = source.nextNode;
        while (node != null) {
            if (map[node.y][node.x] != TARGET) {
                map[node.y][node.x] = PATH;
            }
            node = node.nextNode;
        }

        for (int y = 0; y < map.length; y++) {
            for (int x = 0; x < map[y].length; x++) {
                switch (map[map.length - y - 1][x]) {
                    case 4:
                        System.out.print("#");
                        break;
                    case 3:
                        System.out.print("X");
                        break;
                    case 2:
                        System.out.print("T");
                        break;
                    case 1:
                        System.out.print("S");
                        break;
                    case 0:
                    default:
                        System.out.print("O");
                        break;
                }
            }
            System.out.println("");
        }
    }

    public void printMap() { // for debug
        for (int y = 0; y < map.length; y++) {
            for (int x = 0; x < map[y].length; x++) {
                switch (map[map.length - y - 1][x]) {
                    case 3:
                        System.out.print("X");
                        break;
                    case 2:
                        System.out.print("T");
                        break;
                    case 1:
                        System.out.print("S");
                        break;
                    case 0:
                    default:
                        System.out.print("O");
                        break;
                }
            }
            System.out.println("");
        }
    }

    private QueryCallback queryCallback = new QueryCallback() {

        @Override
        public boolean reportFixture(Fixture fixture) {
            if (fixture.getFilterData().categoryBits == GameManager.WALL_BIT) {
                isWall = true;
            }
            return false;
        }
    };

}
