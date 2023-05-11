// deno run --allow-net lib/live_buggies_web/live/example.js

const urls = [
  "http://localhost:4000/api/game/80125045/player/6a3a7df9/",
  "http://localhost:4000/api/game/80125045/player/6ac5d36f/",
  "http://localhost:4000/api/game/80125045/player/5f799078/"
]

// UTILS
function dedupe(xs) {
  if (xs.length <= 1) return xs;
  return xs.slice(0, 1).concat(dedupe(xs.slice(1).filter((x) => x !== xs[0])));
}

function slidingWindow(arr, step) {
  return arr.map((_, i) => arr.slice(i, i + step)).slice(0, 1 - step);
}

function xy(x, y) {
  return `${x},${y}`
}

function fromXy(xy) {
  return xy.split(',').map(n => parseInt(n, 10))
}

function now() {
  return Date.now() / 1000
}

function intcmp(a, b) {
  return a < b ? -1 : a === b ? 0 : 1
}

function manhattanDistance([x1, y1], [x2, y2]) {
  return Math.abs(x2 - x1) + Math.abs(y2 - y1)
}

// SYS
async function sleep(ms) {
  return new Promise((res) => {
    setTimeout(res, ms);
  });
}

async function callRemote(url) {
  return fetch(url)
    .then((res) => res.json());
}

// HELPERS

function cleanPath(...path) {
  return path.join("/").replace(/\/+/g, "/");
}

function randomWalk() {
  return ["N", "E", "S", "W"][Math.floor(Math.random() * 4)];
}

function parsePos(pos) {
  return pos.split(",").map((num) => parseInt(num, 10));
}

function expand(pos) {
  const [x, y] = parsePos(pos);
  return [
    xy(x, y + 1),
    xy(x + 1, y),
    xy(x, y - 1),
    xy(x - 1, y)
  ];
}

function findCoins(world) {
  return Object.entries(world)
    .filter(([_xy, tile]) => tile === "coin")
    .map(([xy, _tile]) => xy);
}

// LIB

// {}, "3,4", {"3,4": "3,5", "3,5": "3,6"}, ["3,6"]
// {}, "3,8", {},                           ["3,3"]
function search(world, explored, frontier, depth = 0) {
  const RECURSION_LIMIT = 50;
  const unexplored = frontier
    .flatMap((pos1) =>
      expand(pos1)
      .filter((pos2) =>
        ["coin", undefined].includes(world[pos2]) && !(pos2 in explored)
      )
      .map((pos2) => [pos2, pos1])
    );

  explored = { ...explored, ...Object.fromEntries(unexplored) };
  frontier = dedupe(unexplored.map(([pos2, _pos1]) => pos2));

  const result = { explored, depth };
  if (depth > RECURSION_LIMIT) return result;
  return unexplored.length === 0
    ? result
    : search(world, explored, frontier, depth + 1);
}

function treeToPath(start, end, tree, limit = 100) {
  if (limit <= 0) return []
  if (start === end || start == null) return [end];
  const next = tree[start];
  return treeToPath(next, end, tree, limit - 1).concat(start);
}

function pathToDirections(path) {
  return slidingWindow(path.map(parsePos), 2)
    .map(([[x1, y1], [x2, y2]]) => {
      if (x1 > x2) return "W";
      if (x1 < x2) return "E";
      if (y1 > y2) return "N";
      if (y1 < y2) return "S";
      return "";
    });
}

// MAIN
async function main(url) {
  while (true) {
    let resp = await callRemote(cleanPath(url, "info"));
    if (resp.reason === "throttle") {
      console.log("THROTTLED");
      await sleep(1000);
      continue
    }
    if (!resp.success) {
      console.log("ERROR", resp.reason);
      await sleep(1000);
      continue
    }
    const { world, you: { x, y, boom }, players } = resp.result;
    if (boom) return null;
    const you = xy(x, y)

    const coins = findCoins(world).sort((c1, c2) => {
      const md1 = manhattanDistance(fromXy(c1), [x, y])
      const md2 = manhattanDistance(fromXy(c2), [x, y])
      return intcmp(md1, md2)
    });
    const playerXYs = Object.values(players).map(({x, y}) => xy(x, y)).reduce((xys, xy) => ({...xys, [xy]: xy}), {})
    const tree = search(world, playerXYs, [you]).explored;
    const coin = coins[Math.floor(Math.random() * Math.min(3, coins.length))];
    const path = treeToPath(coin, you, tree);
    const directions = pathToDirections(path);
    for (let i = 0; i < directions.length; i++) {
      await sleep(100);
      //await sleep(5);
      resp = await callRemote(cleanPath(url, "move", directions[i]));
      if (!resp.success) break
    }
  }
}

urls.forEach(url => {
  main(url);
})
