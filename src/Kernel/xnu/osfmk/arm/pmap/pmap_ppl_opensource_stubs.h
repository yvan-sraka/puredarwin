/*
 * Declarations for open-source PPL stub implementations.
 */

#ifndef _ARM_PMAP_PPL_OPENSOURCE_STUBS_H_
#define _ARM_PMAP_PPL_OPENSOURCE_STUBS_H_

#include <mach/vm_types.h>
#include <arm/pmap/pmap_internal.h>

void pmap_ppl_lockdown_pages(vm_address_t kva, vm_size_t size,
    uint64_t lockdown_flag, bool ppl_writable);
void pmap_ppl_unlockdown_pages(vm_address_t kva, vm_size_t size,
    uint64_t lockdown_flag, bool ppl_writable);
void *ptep_get_iommu(pt_entry_t *pte_p);

#endif /* _ARM_PMAP_PPL_OPENSOURCE_STUBS_H_ */
