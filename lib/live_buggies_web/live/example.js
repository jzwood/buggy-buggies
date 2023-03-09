const url =
  "http://localhost:4000/api/game/41001658-d462-41d7-854e-0a349d583c13/player/7cdf171c-582e-4cff-868e-ba308a0baf07/move/"

function randomWalk() {
  return ["N", "E", "S", "W"][Math.floor(Math.random() * 4)]
}

async function navigate(direction = "N") {
  const resp = await fetch(url + direction)
  const data = await resp.json()
  console.log(data)
  if (data?.result?.you?.boom === true) {
    console.log("TERMINATING")
  } else {
    const dir = randomWalk()
    setTimeout(() => {
      navigate(dir)
    }, 333)
  }
}

function find_coins(world) {
  return new Set(
    Object.entries(world)
      .filter(([_xy, tile]) => tile === "coin")
      .map(([xy, _tile]) => xy),
  )
}

function expand(pos) {
  const [x, y] = pos.split(",").map((num) => parseInt(num, 10))
  return [
    `${x},${y + 1}`,
    `${sx + 1},${sy}`,
    `${sx},${sy - 1}`,
    `${sx - 1},${sy}`,
  ]
}

// {}, "3,4", {"3,4": "3,5", "3,5": "3,6"}, ["3,6"]
// {}, "3,8", {},                           ["3,3"]
function search(world, explored, frontier) {
  const unexplored = frontier
    .flatMap(pos1 => expand(pos1)
      .filter((pos2) => !(pos2 in world || pos2 in explored))
      .map((pos2) => [pos2, pos1])
    )

  explored = {...explored, ...Object.fromEntries(unexplored)}
  frontier = unexplored.map(([pos2, _pos1]) => pos2)

  return unexplored.length === 0 ? explored : search(world, explored, frontier)
}

navigate()
