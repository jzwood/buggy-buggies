working_dir = Path.dirname(__ENV__.file)
Code.require_file(Path.join(working_dir, "gen_worlds.ex"))

CreateWorlds.get_ascii_worlds
|> CreateWorlds.create_worlds |> IO.inspect
