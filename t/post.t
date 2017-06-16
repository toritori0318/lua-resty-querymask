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
        content_by_lua '
            local querymask = require "resty.querymask"
            q = querymask:new({
                mask_part_string = "@",
                mask_part_length = 2,
                mask_all_string  = "*CSTMASK*",
                mask_hash_seed   = "hogefugapiyo",
                mask_fields = {
                  ["attr1"] = "part",
                  ["attr2"] = "all",
                  ["attr3"] = "hash",
                  ["attr4"] = "trim",
                }
            })
            -- get string
            masked_query_string = q:mask_query_string()

            ngx.header.content_type = "text/plain"

            ngx.say(masked_query_string)
        ';
    }
--- more_headers
Content-Type: application/x-www-form-urlencoded; charset=utf-8
--- request eval
qq{POST /mask\n\r
attr1=hogeeee&attr2=fugaaaa&attr3=piyoooo&attr4=fooooo\r\r
}
--- response_body
attr2=*CSTMASK*&attr3=d042d5d93ccef6382fb22d4cb72e3a3e1be69e71&attr1=ho@@@@@
--- no_error_log
[error]


=== TEST 2: post application/json 
--- http_config eval: $::HttpConfig
--- config
    location /mask {
        content_by_lua '
            local querymask = require "resty.querymask"
            q = querymask:new({
                mask_part_string = "@",
                mask_part_length = 2,
                mask_all_string  = "*CSTMASK*",
                mask_hash_seed   = "hogefugapiyo",
                mask_fields = {
                  ["attr1"] = "part",
                  ["attr2"] = "all",
                  ["attr3"] = "hash",
                  ["attr4"] = "trim",
                }
            })
            -- get string
            masked_query_string = q:mask_query_string()

            ngx.header.content_type = "text/plain"

            ngx.say(masked_query_string)
        ';
    }
--- more_headers
Content-Type: application/json; charset=utf-8
--- request eval
qq{POST /mask\n\r
{"attr1":"hogeeee","attr2":"fugaaaa","attr3":"piyoooo","attr4":"fooooo"}\r\r
}
--- response_body
attr2=*CSTMASK*&attr3=d042d5d93ccef6382fb22d4cb72e3a3e1be69e71&attr1=ho@@@@@
--- no_error_log
[error]

