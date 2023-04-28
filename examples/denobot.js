/*
 * USAGE:
 * host or join game then run:
 * deno run --allow-read --allow-net example.js <domain> <game_id> <secret>
 *
 *  EXAMPLE:
 *  deno run --allow-read --allow-net examples/example.js http://localhost:4000 3ae2ce1a-c45b-4ef1-a30d-1a9efc90d404 e7678bc9-f098-4a36-89b0-bfe2399f35fd e7678bc9-f098-4a36-89b0-bfe2399f35fd
 */

main();

function main() {
  const [domain, gameId, secret] = Deno.args;
  const url = [domain, "api", "game", gameId, "player", secret].join("/");
  return loop(url);
}

async function loop(url) {
  let resp = await callRemote(url + "/info");
  let crashed = false;
  while (!crashed) {
    await sleep(500);
    const { reason, result, success } = resp;
    if (success) {
      let { world, you: { x, y, boom } } = result;
      crashed = boom;
    }
    const dir = randomDirection();
    const move = `/move/${dir}`;
    resp = await callRemote(url + move);
  }
  console.error("CRASHED");
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

// HELPER
function randomDirection() {
  const dirs = ["N", "E", "S", "W"];
  return dirs[Math.floor(Math.random() * dirs.length)];
}
