# Hashcracker CLI

CLI client for hashcracker

## Building

`mix escript.build`

## Usage
```
./hashcracker -h HASH -t HASH_TYPE -a ATTACK_MODE -n WORKERS [options]
./hashcracker --help
```

### Distributed nodes
To start worker nodes
```
cd ../cracker
epmd -daemon
iex --sname <name> -S mix
```

## Options
```
-h, --hash           HASH         base16 encoded hash (lower or upper case)
-t, --hash-type      HASH_TYPE    md5 | ripemd160 | sha | sha224 | sha256 |
                                  sha384 | sha512
-a, --attack         ATTACK_MODE  brute | mask | dictionary
-n, --num-workers    WORKERS      number of parallel workers
-w, --wordlist-path  PATH         path to wordlist for dictionary attack
-m, --mask           MASK         mask for mask attack (see section below)
-i, --increment      START:STOP   increment for mask
-c, --client         NODE_NAME    shortname for this client (defaults to client@hostname)
--worker-nodes       NODE_NAMES   comma separated list of worker shortnames
--cookie             COOKIE       node cookie

Mask attack:
A mask is useful to exploit certain patterns found in passwords,
such an uppercase letter for the first character, a certain
number of lowercase letters after, followed by a number.

This pattern would be represented as the following mask:
?u?l?l?l?d

Each position of a string is replaced with the following character sets:
?l | abcdefghijklmnopqrstuvwxyz
?u | ABCDEFGHIJKLMNOPQRSTUVWXYZ
?d | 0123456789
?s | !"#$%&'()*+,-./:;<=>?@[]^_`{|}~
?a | ?l?u?d?s
```
