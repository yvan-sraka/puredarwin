/*
 * KPI stubs for open-source BCM2837 arm64 builds without Apple proprietary
 * pmap IOMMU / codesigning extensions.
 */

#include <pexpert/arm64/board_config.h>
#include <vm/pmap.h>

#if defined(ARM64_BOARD_CONFIG_BCM2837)

int
pmap_cs_configuration(void)
{
	return 0;
}

bool
pmap_has_iofilter_protected_write(void)
{
	return false;
}

#endif /* ARM64_BOARD_CONFIG_BCM2837 */
