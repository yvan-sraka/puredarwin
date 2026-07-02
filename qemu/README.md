# Booting PureDarwin on Linux with QEMU

PureDarwin builds only on macOS, but older **pre-built disk images** can be booted on Linux with QEMU. This directory provides profiles, download helpers, and launch scripts.

The current source tree (Ventura-era XNU) does not yet produce a bootable image. Use the community releases below to experiment on Linux while development continues.

## Supported images

| Profile | Release | Darwin | Format | Notes |
|---------|---------|--------|--------|-------|
| `pd-17.4` (default) | [PureDarwin 17.4 Beta](https://github.com/PureDarwin/PureDarwin/releases/tag/17.4) | 17 / High Sierra | VMDK (xz) | CLI only, serial console. Best starting point. |
| `pd-xmas-bte` | [XMas Brain Transplant](https://github.com/PureDarwin/LegacyDownloads/releases/tag/PDXMASNBE01) | 9 / Leopard era | 7z (VMDK inside) | Older GUI experiment, Chameleon bootloader. |

## Requirements

On Debian/Ubuntu:

```sh
sudo apt install qemu-system-x86 qemu-utils xz-utils curl p7zip-full
```

On Fedora:

```sh
sudo dnf install qemu-system-x86 qemu-img xz curl p7zip
```

## Quick start (PD-17.4)

```sh
./qemu/fetch-image.sh pd-17.4
./qemu/run.sh pd-17.4
```

The guest prints to your terminal (serial console). The first boot under software emulation (TCG) can take several minutes before you see the Darwin kernel banner.

Press `Ctrl-a` then `x` to exit QEMU.

## Scripts

| Script | Purpose |
|--------|---------|
| `fetch-image.sh` | Download and extract a profile image into `qemu/images/` |
| `run.sh` | Launch QEMU with the selected profile |

Environment overrides:

| Variable | Default | Description |
|----------|---------|-------------|
| `PD_IMAGE_DIR` | `qemu/images` | Where images are stored |
| `PD_MEMORY_MB` | `8192` | Guest RAM |
| `PD_SMP` | `2` | CPU count |
| `PD_ACCEL` | auto (`kvm` if available, else `tcg`) | QEMU accelerator |
| `PD_SERIAL_LOG` | (empty) | If set, mirror serial output to this file |

Examples:

```sh
# Faster boot on a host with /dev/kvm
PD_ACCEL=kvm ./qemu/run.sh pd-17.4

# Log serial output while watching on the terminal
PD_SERIAL_LOG=/tmp/pd.log ./qemu/run.sh pd-17.4

# Use a raw copy instead of VMDK (created by fetch-image.sh)
./qemu/run.sh pd-17.4 --format raw
```

## Hardware profile

PD-17.4 was built and tested with this QEMU machine layout:

- **Architecture:** x86_64 (`qemu-system-x86_64`)
- **Machine:** `pc-i440fx-2.12` (classic PC + SeaBIOS)
- **CPU:** `Penryn` (Core 2 class; important for XNU)
- **RAM:** 8 GB
- **Disk:** IDE/VMDK (`if=ide`)
- **Network:** `rtl8139` with user-mode NAT
- **Console:** serial on stdio (no GUI in PD-17.4)

The image ships with a Chameleon-based bootloader that patches the kernel before handoff. Serial output shows both the bootloader and XNU messages.

## Profile files

Each profile has:

- `profiles/<name>.env` - download URL, filenames, metadata
- `profiles/<name>.ini` - QEMU `-readconfig` device graph (paths patched at runtime)

`run.sh` substitutes the resolved image path into the `.ini` and passes `-cpu Penryn` on the command line (QEMU 8.x does not accept `[cpu]` in readconfig files).

## Troubleshooting

**"Failed to get write lock"** - another QEMU instance is using the image. Stop it or remove stale `*.vmdk.lck` directories.

**No output for a long time** - normal under TCG. Wait 2-5 minutes. Use `PD_ACCEL=kvm` on hardware with Intel VT-x / AMD-V.

**Kernel panic early in boot** - usually wrong CPU model. Do not use `host` or `qemu64`; stick to `Penryn`.

**Want a GUI** - PD-17.4 is serial-only by design, but you can add `-display sdl` or `-display gtk` to `run.sh` for VGA text during early boot. There is no working graphical desktop in this image.

## Relation to the current tree

Building from `main` today installs kernel, kexts, and partial userspace into a DSTROOT layout. Turning that into a bootable disk image requires bootloaders (`boot.efi` branch), `launchd`/`dyld`, and image tooling (`projects/README.md` lists planned `libhfsrw` / `libapfsrw`). The QEMU setup here is for **released** images, not the in-development Ventura build.
