# Hyper Rally (Konami, RC-718) — commented disassembly

A commented disassembly of the 16 KB MSX cartridge, reproducible byte for byte.

**[Read the write-up →](https://antxiko.github.io/HyperRally-disassembly/)**
· [En castellano](README.es.md)

    make            # trace, generate the listing, reassemble it and run the tests
    make verify     # the test that decides: reassembling has to give the ROM back
    make sanity     # that not one byte is left unexplained
    make densidad   # how much is commented, routine by routine
    make web        # rebuild the website

The ROM is **not distributed here**. It goes in the root as `hyperrally.rom`,
16384 bytes, sha256

    eca2c0d6057b3829210b5fccd0d0005ea6ada7560f5446d9bbc2db2d06d96aae

`make comprueba` checks it.

## Where it stands

| | |
|---|---|
| reassembles byte for byte | yes |
| bytes explained | 16,384 of 16,384 (100 %) |
| traced code | 6,452 bytes, 3,350 instructions |
| identified data | 9,932 bytes in 50 named ranges |
| commented | 511 line comments, 15.3 % |
| thin routines (under 10 %) | 0 of 428 |

The annotations live apart from the listing, anchored to the address they
describe, so they survive a re-trace. What the `.notes` file holds:

| | |
|---|---|
| named labels | 429 |
| anchored comments | 476 |
| explained data ranges | 50 |

## What is in here

- `src/hyperrally.asm` — the listing; generated, not hand-edited
- `src/hyperrally.notes` — the annotations, anchored to addresses
- `src/hyperrally.entries` — the entry points, each one justified
- `docs/` — the website, in English and Spanish
- `tools/` — the tracer, the listing generator, the data walkers and the
  script decompressor that draws the website's pictures from the ROM

## The write-up

| | |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | what you need and what each command does |
| [The game](docs/THE-GAME.md) | a twelve-stage rally, a fake-3D road and a dashboard |
| [The cartridge](docs/THE-CARTRIDGE.md) | the header, the memory map and the screen |
| [The code](docs/THE-CODE.md) | the state machine, the script interpreters and the sound |
| [Findings](docs/FINDINGS.md) | what the binary says |
| [In the emulator](docs/IN-THE-EMULATOR.md) | what can be measured, and how |
| [Open questions](docs/OPEN-QUESTIONS.md) | what is still not settled |

See `LEGAL-NOTICE.md`.
