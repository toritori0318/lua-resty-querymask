# lua resty querymask

query mask library.

## Installation

```
luarocks install https://raw.githubusercontent.com/toritori0318/lua-resty-querymask/master/lua-resty-querymask-dev-1.rockspec
```


## Synopsis

### Basic

```lua
server {
    location /mask {
        content_by_lua_block {
            local querymask = require "resty.querymask"
            q = querymask:new({
                mask_part_string = "*",
                mask_part_length = 3,
                mask_all_string  = "*MASK*",
                mask_hash_seed   = "hogefugapiyo",
                mask_fields = {
                  ["attr1"] = "part",
                  ["attr2"] = "all",
                  ["attr3"] = "hash",
                  ["attr4"] = "trim",
                }
            })
            -- get table
            masked_query_table  = q.mask_query_table()
            -- get string
            masked_query_string = q.mask_query_string()

            ngx.header.content_type = "text/plain"

            ngx.say(masked_query_string)
            -- (example)
            --   curl 'http://localhost/mask?attr1=hogeeee&attr2=fugaaaa&attr3=piyoooo&attr4=fooooo'
            -- 
            --   attr1=hog****&attr2=*MASK*&attr3=eoroiaweuroajejrfalwjreoaijrejwaerwaer'
        }
    }
}
```

#### Include Nginx Log

```lua
log_format querymask_format
                  '$remote_addr - $remote_user [$time_local] '
                  '"$request" $status $body_bytes_sent '
                  '"$http_referer" "$http_user_agent" '
                  '"$x_mask_query"'
                  ;

server {


    access_log /var/log/nginx/nginx-access-querymask.log querymask_format;

    # set nginx valiables
    set $x_mask_query '-';

    location /mask {
        content_by_lua_block {
            local querymask = require "resty.querymask"
            q = querymask:new({
                mask_part_string = "*",
                mask_part_length = 3,
                mask_all_string  = "*MASK*",
                mask_hash_seed   = "hogefugapiyo",
                mask_fields = {
                  ["attr1"] = "part",
                  ["attr2"] = "all",
                  ["attr3"] = "hash",
                  ["attr4"] = "trim",
                }
            })
            -- get table
            masked_query_table  = q.mask_query_table()
            -- get string
            masked_query_string = q.mask_query_string()

            -- set nginx valiables
            ngx.var.x_mask_query = masked_query_string

            ngx.header.content_type = "text/plain"

            ngx.say(masked_query_string)
        }
    }
}
```


## Parameters

### mask_part_string

### mask_part_length

### mask_all_string

### mask_hash_seed

### mask_fields

- operation
    - part
    - all
    - hash
    - trim

## For Developer

docker run & run test

```
make docker-test
```

## Authors

* TSUYOSHI TORII (toritori0318)

## License

MIT

