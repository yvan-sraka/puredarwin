# PureDarwin   [![PureDarwin Discord](https://dcbadge.limes.pink/api/server/https://discord.gg/9kz8XXRRcT?style=flat)](https://discord.gg/9kz8XXRRcT)

![logo-sm](https://github.com/user-attachments/assets/ea4bd560-3738-4486-80ab-2f313e4a33a1)

Darwin is the Open Source operating system from Apple that forms the basis for Mac OS X and PureDarwin. PureDarwin is a community project that aims to make Darwin more usable (some people think of it as the informal successor to OpenDarwin).

One current goal of this project is to provide a useful bootable ISO/VM of some recent version of Darwin.

See the [Website](https://www.puredarwin.org) for more information.

## Building PureDarwin

To build PureDarwin, you will need OpenSSL installed, which is used by xar and ld64.
PureDarwin builds only on macOS. It is currently tested with Xcode 15 (required for the
Ventura/Darwin 22 kernel), but should work with any later Xcode.

You will also need zlib, which is used by the DTrace CTF tools used in building the kernel.

The bundled XNU kernel source corresponds to **xnu-8796.141.3** (Darwin 22.6.0, macOS Ventura 13.6).
Building it requires the macOS 13 (Ventura) SDK or later.

### Target architectures

PureDarwin supports two target architectures, selected at CMake configure time via
`-DPUREDARWIN_TARGET_ARCH=<arch>`:

| `PUREDARWIN_TARGET_ARCH` | Platform | Minimum SDK |
|--------------------------|----------|-------------|
| `x86_64` (default)       | Intel Mac / VM | macOS 13 (Ventura) |
| `arm64`                  | Apple Silicon (M-series) | macOS 14 (Sonoma) |

#### Building for arm64 (Apple Silicon)

```sh
cmake -B build-arm64 -DPUREDARWIN_TARGET_ARCH=arm64
cmake --build build-arm64
```

The `arm64` target compiles XNU with `ARCH_CONFIGS=ARM64` and omits x86-only kexts
(AppleAPIC, AppleI386GenericPlatform, AppleIntelPIIXATA, ApplePS2Controller, IOATAFamily).
The bundled XNU 22.6.0 sources include ARM64 machine configs for T6000 (M2), T8101/T8103
(M1), VMAPPLE (virtualised Apple Silicon), and BCM2837 (Raspberry Pi).

> **Note on Apple Silicon booting:** Booting a custom XNU image on Apple Silicon hardware
> requires a compatible iBoot stage-2 loader, Apple-signed firmware, and hardware-specific
> platform drivers (AIC interrupt controller, ANS NVMe, etc.) that Apple has not yet
> open-sourced. The arm64 build target is the first step toward Apple Silicon support;
> full bare-metal boot support is a longer-term project goal.
