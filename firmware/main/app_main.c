#include <stdint.h>
#include <math.h>
#include "sdkconfig.h"
#include "driver/gpio.h"
#include "esp_check.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_rgb.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "baro_altitude.h"
#include "bmi088.h"
#include "horizon_renderer.h"
#include "instrument_screens.h"
#include "instrument_sim.h"
#include "instrument_ui.h"
#include "mcp23008.h"
#include "pins.h"
#include "st7701s.h"
#ifdef CONFIG_EFIS_QEMU
#include "esp_lcd_qemu_rgb.h"
#endif
static const char *TAG="esp32_efis";
#define LCD_PCLK_HZ 30000000
#define QEMU_COMPASS_TEST_COUNT 12
#define QEMU_SCENARIO_SECONDS 6
#ifdef CONFIG_EFIS_BENCH_SIMULATION
#define BENCH_SIMULATION true
#else
#define BENCH_SIMULATION false
#endif
#ifndef CONFIG_EFIS_QEMU
static esp_err_t init_safe_outputs(void){const gpio_config_t o={.pin_bit_mask=(1ULL<<PIN_BMI088_ACC_CS)|(1ULL<<PIN_BMI088_GYRO_CS)|(1ULL<<PIN_LCD_BACKLIGHT_PWM),.mode=GPIO_MODE_OUTPUT};ESP_RETURN_ON_ERROR(gpio_config(&o),TAG,"safe outputs");gpio_set_level(PIN_BMI088_ACC_CS,1);gpio_set_level(PIN_BMI088_GYRO_CS,1);gpio_set_level(PIN_LCD_BACKLIGHT_PWM,0);return ESP_OK;}
static esp_err_t init_rgb_panel(esp_lcd_panel_handle_t*po,uint16_t**f0,uint16_t**f1){const esp_lcd_rgb_panel_config_t c={.clk_src=LCD_CLK_SRC_DEFAULT,.timings={.pclk_hz=LCD_PCLK_HZ,.h_res=AH_DISPLAY_WIDTH,.v_res=AH_DISPLAY_HEIGHT,.hsync_pulse_width=4,.hsync_back_porch=50,.hsync_front_porch=50,.vsync_pulse_width=2,.vsync_back_porch=50,.vsync_front_porch=50},.data_width=16,.num_fbs=2,.hsync_gpio_num=PIN_LCD_HSYNC,.vsync_gpio_num=PIN_LCD_VSYNC,.de_gpio_num=PIN_LCD_DE,.pclk_gpio_num=PIN_LCD_PCLK,.disp_gpio_num=-1,.data_gpio_nums={PIN_LCD_D0,PIN_LCD_D1,PIN_LCD_D2,PIN_LCD_D3,PIN_LCD_D4,PIN_LCD_D5,PIN_LCD_D6,PIN_LCD_D7,PIN_LCD_D8,PIN_LCD_D9,PIN_LCD_D10,PIN_LCD_D11,PIN_LCD_D12,PIN_LCD_D13,PIN_LCD_D14,PIN_LCD_D15},.flags.fb_in_psram=true};esp_lcd_panel_handle_t p=NULL;ESP_RETURN_ON_ERROR(esp_lcd_new_rgb_panel(&c,&p),TAG,"RGB panel");ESP_RETURN_ON_ERROR(esp_lcd_panel_reset(p),TAG,"reset");ESP_RETURN_ON_ERROR(esp_lcd_panel_init(p),TAG,"init");void*a=NULL,*b=NULL;ESP_RETURN_ON_ERROR(esp_lcd_rgb_panel_get_frame_buffer(p,2,&a,&b),TAG,"framebuffers");*po=p;*f0=a;*f1=b;return ESP_OK;}
#else
static esp_err_t init_qemu_panel(esp_lcd_panel_handle_t*p,uint16_t**fb){const esp_lcd_rgb_qemu_config_t c={.width=AH_DISPLAY_WIDTH,.height=AH_DISPLAY_HEIGHT,.bpp=RGB_QEMU_BPP_16};ESP_RETURN_ON_ERROR(esp_lcd_new_rgb_qemu(&c,p),TAG,"QEMU RGB panel");ESP_RETURN_ON_ERROR(esp_lcd_panel_reset(*p),TAG,"QEMU reset");ESP_RETURN_ON_ERROR(esp_lcd_panel_init(*p),TAG,"QEMU init");void*b=NULL;ESP_RETURN_ON_ERROR(esp_lcd_rgb_qemu_get_frame_buffer(*p,&b),TAG,"QEMU framebuffer");*fb=b;return ESP_OK;}
#define QWHITE 0xFFFF
#define QBLACK 0x0000
#define QGREEN 0x07E0
static void qpx(uint16_t*f,int x,int y,uint16_t c){if((unsigned)x<AH_DISPLAY_WIDTH&&(unsigned)y<AH_DISPLAY_HEIGHT)f[y*AH_DISPLAY_WIDTH+x]=c;}
static void qrect(uint16_t*f,int x0,int y0,int x1,int y1,uint16_t c){for(int y=y0;y<=y1;y++)for(int x=x0;x<=x1;x++)qpx(f,x,y,c);}
static const char*qglyph(char c){switch(c){case'N':return"101111111111101";case'E':return"111100110100111";case'S':return"011100010001110";case'W':return"101101111111101";case'0':return"111101101101111";case'1':return"010110010010111";case'2':return"110001111100111";case'3':return"110001111001110";case'4':return"101101111001001";case'5':return"111100110001110";case'6':return"011100111101111";case'7':return"111001010010010";case'8':return"111101111101111";case'9':return"111101111001110";default:return"000000000000000";}}
static void qchar(uint16_t*f,int x,int y,char c,int s,uint16_t col){const char*g=qglyph(c);for(int yy=0;yy<5;yy++)for(int xx=0;xx<3;xx++)if(g[yy*3+xx]=='1')qrect(f,x+xx*s,y+yy*s,x+(xx+1)*s-1,y+(yy+1)*s-1,col);}
static void qheading(uint16_t*f,int heading){char b[4]={(char)('0'+(heading/100)%10),(char)('0'+(heading/10)%10),(char)('0'+heading%10),0};qrect(f,184,202,296,266,QBLACK);for(int i=0;i<3;i++)qchar(f,194+i*32,214,b[i],6,QGREEN);}
static void qcompass_labels(uint16_t*f,const instrument_data_t*d){if(!d->heading_valid)return;static const char labels[4]={'N','E','S','W'};static const int bearings[4]={0,90,180,270};for(int i=0;i<4;i++){float deg=(float)bearings[i]-(float)d->heading_deg;float a=(deg-90.0f)*3.14159265358979323846f/180.0f;int x=240+(int)(cosf(a)*165.0f)-8;int y=240+(int)(sinf(a)*165.0f)-12;qrect(f,x-4,y-4,x+20,y+28,QBLACK);qchar(f,x,y,labels[i],5,QWHITE);}qheading(f,d->heading_deg);}
#endif
void app_main(void){ESP_LOGW(TAG,"ESP32 EFIS - SUPPLEMENTARY/NON-PRIMARY instrument");ESP_LOGW(TAG,"BENCH SIMULATION: %s",BENCH_SIMULATION?"ENABLED - SYNTHETIC DATA":"OFF");instrument_ui_t ui;instrument_ui_init(&ui);instrument_data_t data={0};instrument_sim_t sim;instrument_sim_init(&sim,BENCH_SIMULATION);instrument_sim_step(&sim,0,&data);
#ifdef CONFIG_EFIS_QEMU
static const instrument_sim_scenario_t tests[QEMU_COMPASS_TEST_COUNT]={SIM_SCENARIO_HEADING_NORTH,SIM_SCENARIO_HEADING_NE,SIM_SCENARIO_HEADING_EAST,SIM_SCENARIO_HEADING_SE,SIM_SCENARIO_HEADING_SOUTH,SIM_SCENARIO_HEADING_SW,SIM_SCENARIO_HEADING_WEST,SIM_SCENARIO_HEADING_NW,SIM_SCENARIO_HEADING_WRAP,SIM_SCENARIO_HEADING_ROTATE,SIM_SCENARIO_HEADING_FAIL,SIM_SCENARIO_HEADING_NORTH};ESP_LOGW(TAG,"QEMU MODE: COMPASS ONLY - %d tests",QEMU_COMPASS_TEST_COUNT);ui.panel=PANEL_COMPASS;ui.heading_bug_deg=60;ui.settings_active=false;int test=0;instrument_sim_set_scenario(&sim,tests[test]);instrument_sim_step(&sim,0,&data);data.test_overlay=true;data.test_name=instrument_sim_scenario_name(sim.scenario);data.test_index=1;data.test_count=QEMU_COMPASS_TEST_COUNT;data.test_seconds_left=QEMU_SCENARIO_SECONDS;esp_lcd_panel_handle_t panel=NULL;uint16_t*fb=NULL;ESP_ERROR_CHECK(init_qemu_panel(&panel,&fb));unsigned ticks=0,st=0;while(1){if(++ticks>=5){ticks=0;instrument_sim_step(&sim,.05f,&data);if(++st>=QEMU_SCENARIO_SECONDS*20){st=0;test=(test+1)%QEMU_COMPASS_TEST_COUNT;instrument_sim_set_scenario(&sim,tests[test]);instrument_sim_step(&sim,0,&data);ESP_LOGW(TAG,"QEMU COMPASS TEST %d/%d: %s heading=%d bug=%d",test+1,QEMU_COMPASS_TEST_COUNT,instrument_sim_scenario_name(sim.scenario),data.heading_deg,ui.heading_bug_deg);}data.test_overlay=true;data.test_name=instrument_sim_scenario_name(sim.scenario);data.test_index=test+1;data.test_count=QEMU_COMPASS_TEST_COUNT;data.test_seconds_left=QEMU_SCENARIO_SECONDS-(int)(st/20);instrument_render(fb,AH_DISPLAY_WIDTH,AH_DISPLAY_HEIGHT,&ui,&data);qcompass_labels(fb,&data);ESP_ERROR_CHECK(esp_lcd_rgb_qemu_refresh(panel));}vTaskDelay(pdMS_TO_TICKS(10));}
#else
ESP_ERROR_CHECK(init_safe_outputs());ESP_ERROR_CHECK(mcp23008_init());ESP_ERROR_CHECK(st7701s_gpio_init());ESP_ERROR_CHECK(st7701s_panel_reset());ESP_ERROR_CHECK(st7701s_init_3wire_rgb565());esp_lcd_panel_handle_t panel;uint16_t*fb0,*fb1;ESP_ERROR_CHECK(init_rgb_panel(&panel,&fb0,&fb1));instrument_render(fb0,AH_DISPLAY_WIDTH,AH_DISPLAY_HEIGHT,&ui,&data);instrument_render(fb1,AH_DISPLAY_WIDTH,AH_DISPLAY_HEIGHT,&ui,&data);ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(panel,0,0,AH_DISPLAY_WIDTH,AH_DISPLAY_HEIGHT,fb0));vTaskDelay(pdMS_TO_TICKS(100));gpio_set_level(PIN_LCD_BACKLIGHT_PWM,1);bmi088_status_t imu={0};esp_err_t ie=bmi088_init(&imu);if(ie==ESP_OK)ESP_LOGI(TAG,"BMI088 communication verified");else ESP_LOGE(TAG,"BMI088 failed: %s",esp_err_to_name(ie));uint16_t*draw=fb1;unsigned ticks=0;while(1){bool redraw=false;esp_err_t e=instrument_ui_poll(&ui,&redraw);if(e!=ESP_OK)ESP_LOGW(TAG,"control: %s",esp_err_to_name(e));if(BENCH_SIMULATION&&++ticks>=5){ticks=0;instrument_sim_step(&sim,.05f,&data);redraw=true;}if(redraw){instrument_render(draw,AH_DISPLAY_WIDTH,AH_DISPLAY_HEIGHT,&ui,&data);ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(panel,0,0,AH_DISPLAY_WIDTH,AH_DISPLAY_HEIGHT,draw));draw=draw==fb0?fb1:fb0;}vTaskDelay(pdMS_TO_TICKS(10));}
#endif
}
