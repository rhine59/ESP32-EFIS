/* Experimental second-stage bootloader for the isolated A/B recovery lab.
 * GPIO44 is a BENCH CANDIDATE, not approved production wiring.
 * GPIO0 ROM download mode is untouched. Never flash without bench approval.
 */
#include <stdbool.h>
#include "sdkconfig.h"
#include "esp_log.h"
#include "esp_rom_sys.h"
#include "bootloader_init.h"
#include "bootloader_utility.h"
#include "bootloader_common.h"
#include "soc/soc.h"
#include "soc/gpio_reg.h"

static const char *TAG="redone_boot_lab";
void __attribute__((noreturn)) call_start_cpu0(void) {
    if(bootloader_init()!=ESP_OK) bootloader_reset();
    bootloader_state_t bs={0};
    if(!bootloader_utility_load_partition_table(&bs)) bootloader_reset();
    int selected=bootloader_utility_get_selected_boot_partition(&bs);
    if(selected==INVALID_INDEX) bootloader_reset();
    /* Bench-only input: active low, external pull-up required.
       GPIO44 is shared with UART0 RX on some configurations. */
    /* GPIO input state is sampled directly; electrical input-enable must be verified on hardware. */
    bool held=true;
    for(int i=0;i<8;i++) {
        if((REG_READ(GPIO_IN1_REG) & (1U << (44-32)))!=0) held=false;
        esp_rom_delay_us(1000);
    }
    if(held && bs.factory.size>0) {
        ESP_LOGW(TAG,"Recovery input asserted: choosing factory image");
        selected=FACTORY_INDEX;
    }
    bootloader_utility_load_boot_image(&bs,selected);
}
struct _reent *__getreent(void) { return _GLOBAL_REENT; }
