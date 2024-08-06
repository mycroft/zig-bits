# zig-bits

Some code I wrote in Zig.

## ls

Mini ls implementation.

```sh
$ zig build-exe ls.zig
$ ./ls -a -l
d      144 755 .git
.        9 644 .gitignore
.  2239816 755 hello-world
.  2026000 644 hello-world.o
.      144 644 hello-world.zig
.  2594688 755 ls
.  2497248 644 ls.o
.     2300 644 ls.zig
```

## cat

```sh
$ zig build-exe cat.zig
$ echo "hello world" | ./cat
hello world
$ ./cat /etc/passwd | sha256sum ; bat -p /etc/passwd | sha256sum
ab1bbd05eded906074d2604771db80dca1160d109ab6054709ebcb8570b0b1e8  -
ab1bbd05eded906074d2604771db80dca1160d109ab6054709ebcb8570b0b1e8  -
```

## base64

```sh
$ ./base64 < /etc/passwd | ./base64 -d | sha256sum
ab1bbd05eded906074d2604771db80dca1160d109ab6054709ebcb8570b0b1e8  -
```

## lorem

```sh
$ zig build-exe lorem.zig
$ /lorem 42 2
Lorem ipsum amet inventore recusandae qui eligendi omnis voluptas explicabo ducimus dolore et voluptas et natus rem similique labore odit iste repellendus autem quae et asperiores distinctio aliquid et fuga voluptatibus autem quis ut minima magni nobis eveniet eum quia aut ut.

Aliquam optio facilis praesentium exercitationem sequi aliquam suscipit unde magnam facere omnis tempore ratione unde deleniti magni architecto et non minus quia voluptate itaque similique et porro mollitia consequatur dolores porro quis autem laboriosam omnis voluptatem doloribus qui blanditiis perferendis inventore rerum.
```