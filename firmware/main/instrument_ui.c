#include "instrument_ui.h"

#include "mcp23008.h"
#include "pins.h"
#include "nvs.h"
#include "nvs_flash.h"

#define LONG_PRESS_POLLS 80
#define NVS_NAMESPACE "flight_ui"

esp_err_t instrument_ui_save(const instrument_ui_t *ui)
{
    nvs_handle_t h;
    esp_err_t e=nvs_open(NVS_NAMESPACE,NVS_READWRITE,&h); if(e!=ESP_OK)return e;
    if((e=nvs_set_u8(h,"panel",(uint8_t)ui->panel))==ESP_OK &&
       (e=nvs_set_i16(h,"qnh",(int16_t)ui->qnh_hpa))==ESP_OK &&
       (e=nvs_set_i16(h,"hdgbug",(int16_t)ui->heading_bug_deg))==ESP_OK &&
       (e=nvs_set_i16(h,"bright",(int16_t)ui->brightness_percent))==ESP_OK) e=nvs_commit(h);
    nvs_close(h); return e;
}

void instrument_ui_init(instrument_ui_t *ui)
{
    *ui=(instrument_ui_t){.panel=PANEL_HORIZON,.settings_active=false,.qnh_hpa=1013,.heading_bug_deg=0,.brightness_percent=100};
    esp_err_t e=nvs_flash_init();
    if(e==ESP_ERR_NVS_NO_FREE_PAGES||e==ESP_ERR_NVS_NEW_VERSION_FOUND){nvs_flash_erase();e=nvs_flash_init();}
    if(e!=ESP_OK)return;
    nvs_handle_t h;if(nvs_open(NVS_NAMESPACE,NVS_READONLY,&h)!=ESP_OK)return;
    uint8_t p;int16_t v;
    if(nvs_get_u8(h,"panel",&p)==ESP_OK&&p<PANEL_COUNT)ui->panel=(instrument_panel_t)p;
    if(nvs_get_i16(h,"qnh",&v)==ESP_OK&&v>=950&&v<=1050)ui->qnh_hpa=v;
    if(nvs_get_i16(h,"hdgbug",&v)==ESP_OK&&v>=0&&v<360)ui->heading_bug_deg=v;
    if(nvs_get_i16(h,"bright",&v)==ESP_OK&&v>=10&&v<=100)ui->brightness_percent=v;
    nvs_close(h);
}

esp_err_t instrument_ui_poll(instrument_ui_t *ui,bool *redraw)
{
    static bool initialized;static uint8_t last_ab;static bool last_button=true;static unsigned held;static bool long_fired;
    uint8_t gpio;esp_err_t err=mcp23008_read_gpio(&gpio);if(err!=ESP_OK)return err;*redraw=false;
    bool a=gpio&(1u<<IOX_ENCODER_A),b=gpio&(1u<<IOX_ENCODER_B),button=gpio&(1u<<IOX_ENCODER_PUSH);uint8_t ab=(a?2u:0u)|(b?1u:0u);
    if(!initialized){initialized=true;last_ab=ab;last_button=button;return ESP_OK;}
    if(ui->settings_active&&ab==3&&last_ab!=3){int d=last_ab==1?1:last_ab==2?-1:0;if(d){if(ui->panel==PANEL_ALTIMETER){ui->qnh_hpa+=d;if(ui->qnh_hpa<950)ui->qnh_hpa=950;if(ui->qnh_hpa>1050)ui->qnh_hpa=1050;}else if(ui->panel==PANEL_COMPASS){ui->heading_bug_deg=(ui->heading_bug_deg+d+360)%360;}else{ui->brightness_percent+=d*5;if(ui->brightness_percent<10)ui->brightness_percent=10;if(ui->brightness_percent>100)ui->brightness_percent=100;}*redraw=true;}}
    last_ab=ab;
    if(!button){if(held<LONG_PRESS_POLLS+1)held++;if(held>=LONG_PRESS_POLLS&&!long_fired){ui->settings_active=!ui->settings_active;long_fired=true;*redraw=true;if(!ui->settings_active)instrument_ui_save(ui);}}
    else if(!last_button){if(!long_fired){if(ui->settings_active){ui->settings_active=false;instrument_ui_save(ui);}else{ui->panel=(instrument_panel_t)((ui->panel+1)%PANEL_COUNT);instrument_ui_save(ui);}*redraw=true;}held=0;long_fired=false;}
    last_button=button;return ESP_OK;
}
