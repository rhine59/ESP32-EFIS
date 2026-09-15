#include "instrument_screens.h"
#include <math.h>
#include <stdlib.h>
#include "horizon_renderer.h"

#define BLACK 0x0000
#define WHITE 0xFFFF
#define RED 0xF800
#define YELLOW 0xFFE0
#define GREY 0x4208
#define CYAN 0x07FF

static void px(uint16_t*f,int w,int h,int x,int y,uint16_t c){if((unsigned)x<(unsigned)w&&(unsigned)y<(unsigned)h)f[y*w+x]=c;}
static void ln(uint16_t*f,int w,int h,int x0,int y0,int x1,int y1,uint16_t c){int dx=abs(x1-x0),sx=x0<x1?1:-1,dy=-abs(y1-y0),sy=y0<y1?1:-1,e=dx+dy;for(;;){px(f,w,h,x0,y0,c);if(x0==x1&&y0==y1)break;int e2=2*e;if(e2>=dy){e+=dy;x0+=sx;}if(e2<=dx){e+=dx;y0+=sy;}}}
static void fill(uint16_t*f,int w,int h,uint16_t c){for(int i=0;i<w*h;i++)f[i]=c;}
static void rect(uint16_t*f,int w,int h,int x0,int y0,int x1,int y1,uint16_t c){for(int y=y0;y<=y1;y++)for(int x=x0;x<=x1;x++)px(f,w,h,x,y,c);}
static void circ(uint16_t*f,int w,int h,int cx,int cy,int r,uint16_t c){int x=r,y=0,e=0;while(x>=y){int p[8][2]={{x,y},{y,x},{-y,x},{-x,y},{-x,-y},{-y,-x},{y,-x},{x,-y}};for(int i=0;i<8;i++)px(f,w,h,cx+p[i][0],cy+p[i][1],c);y++;if(e<=0)e+=2*y+1;if(e>0){x--;e-=2*x+1;}}}
static void radial(uint16_t*f,int w,int h,float deg,int r0,int r1,uint16_t c){float a=(deg-90)*M_PI/180.0f;int cx=w/2,cy=h/2;ln(f,w,h,cx+(int)(cosf(a)*r0),cy+(int)(sinf(a)*r0),cx+(int)(cosf(a)*r1),cy+(int)(sinf(a)*r1),c);}
static void invalid(uint16_t*f,int w,int h){for(int d=-3;d<=3;d++){ln(f,w,h,95+d,95,w-96+d,h-96,RED);ln(f,w,h,w-96+d,95,95+d,h-96,RED);}}
static void box(uint16_t*f,int w,int h,int x0,int y0,int x1,int y1,uint16_t c){ln(f,w,h,x0,y0,x1,y0,c);ln(f,w,h,x1,y0,x1,y1,c);ln(f,w,h,x1,y1,x0,y1,c);ln(f,w,h,x0,y1,x0,y0,c);}

/* Permanent high-contrast SIM flag whenever any displayed values are synthetic. */
static void sim_marker(uint16_t*f,int w,int h){
    const int x=184,y=h-54,s=4;
    rect(f,w,h,x-12,y-10,x+124,y+42,RED);
    /* S */
    rect(f,w,h,x,y,x+28,y+5,WHITE);rect(f,w,h,x,y,x+5,y+18,WHITE);rect(f,w,h,x,y+16,x+28,y+21,WHITE);rect(f,w,h,x+23,y+18,x+28,y+34,WHITE);rect(f,w,h,x,y+32,x+28,y+37,WHITE);
    /* I */
    rect(f,w,h,x+43,y,x+71,y+5,WHITE);rect(f,w,h,x+54,y,x+60,y+37,WHITE);rect(f,w,h,x+43,y+32,x+71,y+37,WHITE);
    /* M */
    rect(f,w,h,x+86,y,x+91,y+37,WHITE);rect(f,w,h,x+115,y,x+120,y+37,WHITE);for(int i=0;i<15;i++){rect(f,w,h,x+91+i,y+i,x+95+i,y+i+s,WHITE);rect(f,w,h,x+111-i,y+i,x+115-i,y+i+s,WHITE);}
}

/* Classic aircraft altimeter: 100-ft long hand, 1000-ft medium hand and 10000-ft short hand. */
static void altimeter(uint16_t*f,int w,int h,const instrument_ui_t*u,const instrument_data_t*d){fill(f,w,h,BLACK);int r=w/2-24;for(int k=0;k<3;k++)circ(f,w,h,w/2,h/2,r-k,WHITE);for(int i=0;i<50;i++)radial(f,w,h,i*7.2f,r-(i%5?12:28),r,WHITE);if(d->altitude_valid){int a=d->altitude_ft<0?0:d->altitude_ft;radial(f,w,h,(a%1000)*.36f,18,r-38,WHITE);radial(f,w,h,(a%10000)*.036f,18,r-72,WHITE);radial(f,w,h,(a%100000)*.0036f,18,r-112,WHITE);}else invalid(f,w,h);box(f,w,h,162,350,318,398,u->settings_active?YELLOW:GREY);for(int i=0;i<5;i++)ln(f,w,h,177,374+i,303,374+i,WHITE);if(u->settings_active)for(int k=0;k<2;k++)circ(f,w,h,w/2,h/2,r-8-k,YELLOW);}

/* Rotating-card presentation: fixed aircraft/lubber line, card and heading bug rotate beneath it. */
static void compass(uint16_t*f,int w,int h,const instrument_ui_t*u,const instrument_data_t*d){fill(f,w,h,BLACK);int r=w/2-25;for(int k=0;k<3;k++)circ(f,w,h,w/2,h/2,r-k,WHITE);float hdg=d->heading_valid?(float)d->heading_deg:0.0f;for(int i=0;i<72;i++){float bearing=i*5.0f-hdg;radial(f,w,h,bearing,r-(i%2?10:(i%6?18:30)),r,WHITE);}ln(f,w,h,w/2,18,w/2-13,48,YELLOW);ln(f,w,h,w/2,18,w/2+13,48,YELLOW);ln(f,w,h,w/2-13,48,w/2+13,48,YELLOW);ln(f,w,h,w/2,170,w/2,310,YELLOW);ln(f,w,h,165,245,315,245,YELLOW);ln(f,w,h,205,305,w/2,280,YELLOW);ln(f,w,h,275,305,w/2,280,YELLOW);radial(f,w,h,(float)u->heading_bug_deg-hdg,r-38,r-8,YELLOW);if(!d->heading_valid)invalid(f,w,h);if(u->settings_active)for(int k=0;k<2;k++)circ(f,w,h,w/2,h/2,r-8-k,YELLOW);}

/* PFD-style horizon shell. Live pitch/roll arrives with the AHRS milestone; optional altitude/heading fields only appear when their sources are valid. */
static void pfd(uint16_t*f,int w,int h,const instrument_ui_t*u,const instrument_data_t*d){horizon_render_static(f,w,h);for(int a=-60;a<=60;a+=10)radial(f,w,h,(float)a,194,(a%30==0)?224:214,WHITE);ln(f,w,h,w/2,15,w/2-11,42,YELLOW);ln(f,w,h,w/2,15,w/2+11,42,YELLOW);box(f,w,h,362,174,467,306,d->altitude_valid?WHITE:GREY);box(f,w,h,146,18,334,64,d->heading_valid?WHITE:GREY);if(!d->attitude_valid)invalid(f,w,h);if(u->settings_active)box(f,w,h,155,414,325,458,YELLOW);}

void instrument_render(uint16_t*f,int w,int h,const instrument_ui_t*u,const instrument_data_t*d){switch(u->panel){case PANEL_HORIZON:pfd(f,w,h,u,d);break;case PANEL_ALTIMETER:altimeter(f,w,h,u,d);break;case PANEL_COMPASS:compass(f,w,h,u,d);break;default:fill(f,w,h,BLACK);}if(d->simulated)sim_marker(f,w,h);}
