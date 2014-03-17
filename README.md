## Using github oauth to keeping stranger out

### Prerequisites

* [Register a github oauth application](https://github.com/settings/applications/new)

* nodejs >= 0.10.26

* curl (for remote installation)

### Install

```bash
[sudo] bash -c "$(curl -fsSL https://raw.github.com/Wiredcraft/bouncer/master/install.sh)"
```

### Security

This software useing brower token cookie to identify visitor,

in order to protect token cookie, there are another signed cookie to make sure the token cookie is valid.

You can change the value of the key `secret` in `conifg.json` to change how the proecting token was produced.

**Warning:** Do not leak this `secret` to stranger, otherwise this software maybe useless.
