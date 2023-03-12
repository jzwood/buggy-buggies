const url =
  "http://localhost:4000/api/game/d5bfcc54-58b4-493c-9235-75446f45409c/player/a56cc671-93e8-4e4e-adae-e55d156d5d84/move/"

function randomWalk() {
  return ["N", "E", "S", "W"][Math.floor(Math.random() * 4)]
}

async function navigate(direction = "N") {
  fetch(url + direction)
    .then(res => res.json())
    .then(data => {
        console.log(data)
      const result = data?.data ?? {}
      if (result.you?.boom === true) {
        console.log("game over")
      } else {
        const directions = decide(result)
        //const dir = randomWalk()
        directions.each(async (dir) => {
          await fetch(url + dir)
          navigate(dir)
        })
        //setTimeout(() => {
          //navigate(dir)
        //}, 333)
      }
    })
    .catch(err => {
      console.log("something went wrong", err)
    })
}

function decide({world, you: { x, y }}) {
  const coins = findCoins(world)
  const spanningTree = search(world, {}, [`${x},${y}`])
  const tree = search(world, {}, [you]).explored
  const coin = coins[0]
  const path = treeToPath(coin, you, tree)
  const directions = pathToDirections(path)
  return directions
}

function findCoins(world) {
  return new Set(
    Object.entries(world)
      .filter(([_xy, tile]) => tile === "coin")
      .map(([xy, _tile]) => xy),
  )
}

function parsePos(pos) {
  return pos.split(",").map((num) => parseInt(num, 10))
}

function expand(pos) {
  const [x, y] = parsePos(pos)
  return [
    `${x},${y + 1}`,
    `${x + 1},${y}`,
    `${x},${y - 1}`,
    `${x - 1},${y}`,
  ]
}

const dedupe = (xs) => {
  if (xs.length <= 1) return xs
  return xs.slice(0, 1).concat(dedupe(xs.slice(1).filter((x) => x !== xs[0])))
}

// {}, "3,4", {"3,4": "3,5", "3,5": "3,6"}, ["3,6"]
// {}, "3,8", {},                           ["3,3"]
function search(world, explored, frontier, depth = 0) {
  const RECURSION_LIMIT = 50
  const unexplored = frontier
    .flatMap(pos1 => expand(pos1)
      .filter((pos2) => ["coin", undefined].includes(world[pos2]) && !(pos2 in explored))
      .map((pos2) => [pos2, pos1])
    )

  explored = {...explored, ...Object.fromEntries(unexplored)}
  frontier = dedupe(unexplored.map(([pos2, _pos1]) => pos2))

  const result = {explored, depth}
  if (depth > RECURSION_LIMIT) return result
  return unexplored.length === 0 ? result : search(world, explored, frontier, depth + 1)
}

function treeToPath(start, end, tree) {
  if (start === end || start == null) return [end]
  const next = tree[start]
  return treeToPath(next, end, tree).concat(start)
}

function window(arr, step) {
  return arr.map((_, i) => arr.slice(i, i + step)).slice(0, 1 - step)
}

function pathToDirections(path) {
  return window(path.map(parsePos), 2)
    .map(([[x1, y1], [x2, y2]]) => {
      if (x1 > x2) return 'E'
      if (x1 < x2) return 'W'
      if (y1 > y2) return 'N'
      if (y1 < y2) return 'S'
      return ''
    })
}

//const result = search(world, {}, ["21,16"])
//console.log(result)

const world = { "11,19": "wall", "0,6": "wall", "21,16": "tree", "14,12": "wall", "14,0": "wall", "14,21": "wall", "27,9": "wall", "27,8": "wall", "6,20": "coin", "20,0": "wall", "0,8": "wall", "7,21": "wall", "24,12": "wall", "10,12": "wall", "24,21": "wall", "0,2": "wall", "23,21": "wall", "19,21": "wall", "2,18": "coin", "27,10": "wall", "7,5": "wall", "2,0": "wall", "12,12": "wall", "19,14": "tree", "0,0": "wall", "1,20": "water", "27,4": "wall", "13,21": "wall", "8,21": "wall", "27,18": "wall", "8,12": "wall", "24,7": "wall", "3,17": "wall", "5,5": "wall", "15,3": "portal", "27,3": "wall", "21,0": "wall", "12,5": "wall", "27,1": "wall", "0,14": "wall", "27,21": "wall", "27,11": "wall", "1,1": "coin", "23,0": "wall", "24,11": "wall", "0,13": "wall", "0,21": "wall", "27,16": "wall", "15,21": "wall", "24,13": "wall", "24,8": "wall", "0,1": "wall", "27,6": "wall", "0,3": "wall", "5,0": "wall", "1,0": "wall", "4,21": "wall", "10,19": "water", "22,0": "wall", "18,19": "wall", "0,7": "wall", "27,12": "wall", "8,5": "wall", "27,7": "wall", "9,19": "water", "9,4": "coin", "3,19": "wall", "0,17": "wall", "9,21": "wall", "4,9": "tree", "27,19": "wall", "0,18": "wall", "24,10": "wall", "20,21": "wall", "15,12": "wall", "8,13": "wall", "25,8": "coin", "16,19": "wall", "10,7": "coin", "6,3": "coin", "7,0": "wall", "2,21": "wall", "8,19": "water", "15,17": "wall", "12,0": "wall", "15,20": "wall", "11,12": "wall", "15,0": "wall", "3,10": "tree", "17,21": "wall", "6,16": "coin", "17,19": "wall", "8,14": "wall", "27,17": "wall", "16,12": "wall", "0,15": "wall", "3,21": "wall", "0,4": "wall", "24,9": "wall", "3,0": "wall", "6,7": "coin", "1,21": "wall", "5,12": "portal", "27,15": "wall", "5,19": "wall", "7,19": "water", "12,21": "wall", "14,19": "wall", "19,0": "wall", "26,0": "wall", "4,5": "wall", "8,10": "wall", "22,21": "wall", "18,0": "wall", "23,17": "spawn", "4,14": "tree", "27,13": "wall", "27,2": "wall", "10,5": "wall", "26,21": "wall", "5,21": "wall", "13,0": "wall", "18,8": "portal", "24,3": "coin", "15,19": "wall", "10,0": "wall", "9,5": "wall", "27,5": "wall", "10,21": "wall", "6,0": "wall", "27,20": "wall", "4,0": "wall", "9,12": "wall", "25,0": "wall", "0,9": "wall", "0,16": "wall", "13,12": "wall", "18,21": "wall", "12,19": "wall", "8,11": "wall", "11,5": "wall", "6,5": "wall", "0,12": "wall", "11,21": "wall", "0,20": "wall", "9,0": "wall", "6,19": "water", "27,0": "wall", "3,18": "wall", "21,21": "wall", "27,14": "wall", "15,18": "wall", "24,6": "wall", "11,10": "spawn", "0,10": "wall", "16,0": "wall", "25,21": "wall", "0,5": "wall", "17,0": "wall", "8,0": "wall", "16,21": "wall", "19,15": "tree", "0,11": "wall", "6,21": "wall", "11,0": "wall", "24,0": "wall", "3,16": "wall", "11,16": "tree", "4,19": "wall", "0,19": "wall" }
const coin = "6,20"
const you = "10,11"

const tree = search(world, {}, [you]).explored
//console.log(tree)
const path = treeToPath(coin, you, tree)

const directions = pathToDirections(path)
console.log(directions)

//navigate()


