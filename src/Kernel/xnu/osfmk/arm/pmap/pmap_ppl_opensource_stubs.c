/*
 * Stub PPL entry points for open-source arm64 builds without Apple's
 * proprietary Page Protection Layer library.
 */

#include <arm/pmap/pmap_internal.h>

void
pmap_ppl_lockdown_pages(vm_address_t kva __unused, vm_size_t size __unused,
    uint64_t lockdown_flag __unused, bool ppl_writable __unused)
{
}

void
pmap_ppl_unlockdown_pages(vm_address_t kva __unused, vm_size_t size __unused,
    uint64_t lockdown_flag __unused, bool ppl_writable __unused)
{
}

#ifdef PVH_FLAG_IOMMU
void *
ptep_get_iommu(pt_entry_t *pte_p __unused)
{
	return NULL;
}
#endif /* PVH_FLAG_IOMMU */
