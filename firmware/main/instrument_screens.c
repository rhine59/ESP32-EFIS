#include "instrument_screens.h"

#include <math.h>
#include <stdio.h>
#include <string.h>
#include "horizon_renderer.h"

#define BLACK  0x0000
#define WHITE  0xFFFF
#define RED    0xF800
#define YELLOW 0xFFE0
#define GREY   0x4208

static void pixel(uint16_t *f,int w,int h,int x,int y,uint16_t c){if((unsigned)x<(unsigned)w&&(unsigned)y<(unsigned)h)f[y*w+x]=c;}
static void line(uint16_t*f,int w,int h,int x0,int y0,int x1,int y1,uint16_t c){int dx=abs(x1-x0),sx=x0<x1?1:-1,dy=-abs(y1-y0),sy=y0<y1?1:-1,e=dx+dy;for(;;){pixel(f,w,h,x0,y0,c);if(x0==x1&&y0==y1)break;int e2=2*e;if(e2>=dy){e+=dy;x0+=sx;}if(e2<=dx){e+=dx;y0+=sy;}}}
static void fill(uint16_t*f,int w,int h,uint16_t c){for(int i=0;i<w*h;i++)f[i]=c;}
static void circle(uint16_t*f,int w,int h,int cx,int cy,int r,uint16_t c){int x=r,y=0,e=0;while(x>=y){pixel(f,w,h,cx+x,cy+y,c);pixel(f,w,h,cx+y,cy+x,c);pixel(f,w,h,cx-y,cy+x,c);pixel(f,w,h,cx-x,cy+y,c);pixel(f,w,h,cx-x,cy-y,c);pixel(f,w,h,cx-y,cy-x,c);pixel(f,w,h,cx+y,cy-x,c);pixel(f,w,h,cx+x,cy-y,c);y++;if(e<=0)e+=2*y+1;if(e>0){x--;e-=2*x+1;}}}

static void invalid_cross(uint16_t*f,int w,int h){for(int d=-4;d<=4;d++){line(f,w,h,75+d,75,w-76+d,h-76,RED);line(f,w,h,w-76+d,75,75+d,h-76,RED);}}

static void radial(uint16_t*f,int w,int h,float deg,int r0,int r1,uint16_t c){float a=(deg-90.0f)*(float)M_PI/180.0f;int cx=w/2,cy=h/2;line(f,w,h,cx+(int)(cosf(a)*r0),cy+(int)(sinf(a)*r0),cx+(int)(cosf(a)*r1),cy+(int)(sinf(a)*r1),c);}

static void render_altimeter(uint16_t*f,int w,int h,const instrument_ui_t*ui,const instrument_data_t*d){fill(f,w,h,BLACK);int r=w/2-28;for(int k=0;k<3;k++)circle(f,w,h,w/2,h/2,r-k,WHITE);for(int i=0;i<50;i++)radial(f,w,h,i*7.2f,r-(i%5?10:22),r,WHITE);if(d->altitude_valid){int a=d->altitude_ft<0?0:d->altitude_ft;radial(f,w,h,(a%1000)*0.36f,0,r-35,WHITE);radial(f,w,h,(a%10000)*0.036f,0,r-62,WHITE);}else invalid_cross(f,w,h);/* QNH setting is retained even before a pressure sensor is fitted. */for(int x=175;x<305;x++){pixel(f,w,h,x,355,GREY);pixel(f,w,h,x,395,GREY);}if(ui->settings_active){for(int k=0;k<3;k++)circle(f,w,h,w/2,h/2,r-8-k,YELLOW);}}

static void render_compass(uint16_t*f,int w,int h,const instrument_ui_t*ui,const instrument_data_t*d){fill(f,w,h,BLACK);int r=w/2-30;for(int k=0;k<3;k++)circle(f,w,h,w/2,h/2,r-k,WHITE);for(int i=0;i<36;i++)radial(f,w,h,i*10,r-(i%3?10:22),r,WHITE);/* fixed lubber line */line(f,w,h,w/2,22,w/2-10,48,YELLOW);line(f,w,h,w/2,22,w/2+10,48,YELLOW);if(d->heading_valid){radial(f,w,h,(float)(360-d->heading_deg),0,r-38,WHITE);}else invalid_cross(f,w,h);/* heading bug */radial(f,w,h,(float)ui->heading_bug_deg,r-34,r-12,YELLOW);if(ui->settings_active){for(int k=0;k<3;k++)circle(f,w,h,w/2,h/2,r-8-k,YELLOW);}}

void instrument_render(uint16_t *fb,int w,int h,const instrument_ui_t *ui,const instrument_data_t *data){switch(ui->panel){case PANEL_HORIZON:horizon_render_static(fb,w,h);if(!data->attitude_valid)invalid_cross(fb,w,h);break;case PANEL_ALTIMETER:render_altimeter(fb,w,h,ui,data);break;case PANEL_COMPASS:render_compass(fb,w,h,ui,data);break;default:fill(fb,w,h,BLACK);break;}}
