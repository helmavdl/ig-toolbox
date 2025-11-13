# How to use the Makefile

## Build for your current machine and test it
make build
make test
make alias

## Occasionally clean up old images but keep last 5
make clean-old

## Be more aggressive: keep last 7, dry-run first
N=7 DRY_RUN=1 make clean-old
N=7 make clean-old

## Nuke everything ig-toolbox and dangling layers
make purge
