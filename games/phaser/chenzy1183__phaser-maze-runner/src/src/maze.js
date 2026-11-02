// 迷宫生成与寻路工具
// 网格表示：grid[y][x]，1 = 墙，0 = 通路。
// cols x rows 个"房间"会映射成 (2*cols+1) x (2*rows+1) 的瓦片网格。
const Maze = {
  /**
   * 使用"递归回溯"（深度优先 + 显式栈）生成完美迷宫，
   * 然后按 braid 比例随机打通部分墙体，制造环路。
   */
  generate(cols, rows, braid = 0, rng = Math.random) {
    const W = cols * 2 + 1;
    const H = rows * 2 + 1;
    const grid = Array.from({ length: H }, () => new Array(W).fill(1));
    const visited = Array.from({ length: rows }, () => new Array(cols).fill(false));
    const dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];

    const stack = [[0, 0]];
    visited[0][0] = true;
    grid[1][1] = 0;

    while (stack.length) {
      const [cx, cy] = stack[stack.length - 1];
      const options = dirs.filter(([dx, dy]) => {
        const nx = cx + dx;
        const ny = cy + dy;
        return nx >= 0 && ny >= 0 && nx < cols && ny < rows && !visited[ny][nx];
      });

      if (!options.length) {
        stack.pop();
        continue;
      }

      const [dx, dy] = options[Math.floor(rng() * options.length)];
      const nx = cx + dx;
      const ny = cy + dy;
      visited[ny][nx] = true;
      grid[cy * 2 + 1 + dy][cx * 2 + 1 + dx] = 0; // 打通中间的墙
      grid[ny * 2 + 1][nx * 2 + 1] = 0;
      stack.push([nx, ny]);
    }

    if (braid > 0) {
      for (let y = 1; y < H - 1; y++) {
        for (let x = 1; x < W - 1; x++) {
          if (grid[y][x] !== 1) continue;
          const horiz = grid[y][x - 1] === 0 && grid[y][x + 1] === 0 && grid[y - 1][x] === 1 && grid[y + 1][x] === 1;
          const vert = grid[y - 1][x] === 0 && grid[y + 1][x] === 0 && grid[y][x - 1] === 1 && grid[y][x + 1] === 1;
          if ((horiz || vert) && rng() < braid) grid[y][x] = 0;
        }
      }
    }

    return { grid, width: W, height: H };
  },

  /** BFS 计算从 start 出发到每个通路格子的步数，不可达为 -1 */
  distances(grid, start) {
    const H = grid.length;
    const W = grid[0].length;
    const dist = Array.from({ length: H }, () => new Array(W).fill(-1));
    const queue = [[start.x, start.y]];
    dist[start.y][start.x] = 0;
    let head = 0;
    while (head < queue.length) {
      const [x, y] = queue[head++];
      for (const [dx, dy] of [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ]) {
        const nx = x + dx;
        const ny = y + dy;
        if (ny < 0 || nx < 0 || ny >= H || nx >= W) continue;
        if (grid[ny][nx] !== 0 || dist[ny][nx] !== -1) continue;
        dist[ny][nx] = dist[y][x] + 1;
        queue.push([nx, ny]);
      }
    }
    return dist;
  },

  /** BFS 最短路径，返回 [{x,y}, ...]（含起点与终点），无解返回 null */
  shortestPath(grid, start, goal) {
    const H = grid.length;
    const W = grid[0].length;
    const prev = Array.from({ length: H }, () => new Array(W).fill(null));
    const seen = Array.from({ length: H }, () => new Array(W).fill(false));
    const queue = [[start.x, start.y]];
    seen[start.y][start.x] = true;
    let head = 0;
    while (head < queue.length) {
      const [x, y] = queue[head++];
      if (x === goal.x && y === goal.y) break;
      for (const [dx, dy] of [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ]) {
        const nx = x + dx;
        const ny = y + dy;
        if (ny < 0 || nx < 0 || ny >= H || nx >= W) continue;
        if (grid[ny][nx] !== 0 || seen[ny][nx]) continue;
        seen[ny][nx] = true;
        prev[ny][nx] = { x, y };
        queue.push([nx, ny]);
      }
    }
    if (!seen[goal.y][goal.x]) return null;
    const path = [];
    let cur = { x: goal.x, y: goal.y };
    while (cur) {
      path.push(cur);
      cur = prev[cur.y][cur.x];
    }
    return path.reverse();
  },
};
