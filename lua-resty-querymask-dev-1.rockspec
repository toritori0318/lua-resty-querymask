package = "lua-resty-querymask"
version = "dev-1"
source = {
    url = "https://github.com/toritori0318/lua-resty-querymask/archive/master.tar.gz",
    dir = "lua-resty-querymask-master"
}
description = {
    summary = "querymask library",
    detailed = [[querymask library]],
    homepage = "https://github.com/toritori0318/lua-resty-querymask",
    license = "MIT",
    maintainer = "toritori0318"
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
        ["resty.querymask"] = "lib/resty/querymask.lua",
    }
}
