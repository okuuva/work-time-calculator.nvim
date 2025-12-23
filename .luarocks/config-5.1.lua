local tree = os_getenv("LUAROCKS_TREE")
lua_version = "5.1"
variables = {
  LUA = tree .. "/bin/nlua",
  LUA_BINDIR = tree .. "/bin",
  LUA_DIR = tree,
}
