working_dir = Path.dirname(__ENV__.file)
Code.require_file(Path.join(working_dir, "gen_worlds.ex"))

CreateWorlds.create_worlds()
|> Enum.map(&CreateWorlds.to_ascii/1)
|> Enum.map(&IO.puts/1)
