if(PUREDARWIN_TARGET_ARCH STREQUAL "x86_64")
    # x86/PC-specific drivers: APIC interrupt controller, Intel platform glue,
    # IDE/ATA storage, PS/2 input, and ACPI inline I/O. These have no arm64
    # equivalent and are not compiled when targeting Apple Silicon.
    add_subdirectory(AppleAPIC)
    add_subdirectory(AppleI386GenericPlatform)
    add_subdirectory(AppleIntelPIIXATA)
    add_subdirectory(ApplePS2Controller)
    add_subdirectory(IOATAFamily)
    add_subdirectory(IOACPIFamily)
endif()

# Architecture-neutral kexts compiled for all targets
add_subdirectory(IOPCIFamily)
add_subdirectory(IOStorageFamily)
add_subdirectory(corecrypto)
add_subdirectory(pthread)
