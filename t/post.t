use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

plan tests => repeat_each() * (blocks() * 3);

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: post
--- http_config eval: $::HttpConfig
--- config
    location /mask {
        content_by_lua_block {
            local querymask = require "resty.querymask"
            q = querymask:new({
                mode = "whitelist",
                mask_part_string = "*",
                mask_part_length = 2,
                mask_fill_string = "*CSTMASK*",
                mask_hash_seed   = "hogefugapiyo",
                fields = {
                  origin = {"attr1"},
                  part   = {"attr3"},
                  fill   = {"attr4"},
                  hash   = {"attr5"},
                }
            })
            -- get string
            masked_query_string = q:mask_query_string()

            ngx.header.content_type = "text/plain"

            ngx.say(masked_query_string)
        }
    }
--- more_headers
Content-Type: application/x-www-form-urlencoded; charset=utf-8
--- request eval
qq{POST /mask\n\r
attr1=hogeeee&attr2=fugaaaa&attr3=piyoooo&attr4=fooooo&attr5=barrrrr\r\r
}
--- response_body
attr5=d4e511badd25d97eaec12ab18b6ca7009d118a34&attr1=hogeeee&attr3=pi*****&attr4=*CSTMASK*
--- no_error_log
[error]


=== TEST 2: post application/json 
--- http_config eval: $::HttpConfig
--- config
    location /mask {
        content_by_lua_block {
            local querymask = require "resty.querymask"
            q = querymask:new({
                mode = "whitelist",
                mask_part_string = "*",
                mask_part_length = 2,
                mask_all_string  = "*CSTMASK*",
                mask_hash_seed   = "hogefugapiyo",
                fields = {
                  origin = {"attr1"},
                  part   = {"attr3"},
                  fill   = {"attr4"},
                  hash   = {"attr5"},
                }
            })
            -- get string
            masked_query_string = q:mask_query_string()

            ngx.header.content_type = "text/plain"

            ngx.say(masked_query_string)
        }
    }
--- more_headers
Content-Type: application/json; charset=utf-8
--- request eval
qq{POST /mask\n\r
{"attr1":"hogeeee","attr2":"fugaaaa","attr3":"piyoooo","attr4":"fooooo","attr5":"barrrrr"}\r\r
}
--- response_body
attr5=d4e511badd25d97eaec12ab18b6ca7009d118a34&attr1=hogeeee&attr3=pi*****&attr4=-
--- no_error_log
[error]

