#include "instrument_screens.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "horizon_renderer.h"

#define BLACK 0x0000
#define WHITE 0xFFFF
#define RED 0xF800
#define YELLOW 0xFFE0
#define GREY 0x4208
#define GREEN 0x07E0

static void px(uint16_t*f,int w,int h,int x,int y,uint16_t c){if((unsigned)x<(unsigned)w&&(unsigned)y<(unsigned)h)f[y*w+x]=c;}
static void ln(uint16_t*f,int w,int h,int x0,int y0,int x1,int y1,uint16_t c){int dx=abs(x1-x0),sx=x0<x1?1:-1,dy=-abs(y1-y0),sy=y0<y1?1:-1,e=dx+dy;for(;;){px(f,w,h,x0,y0,c);if(x0==x1&&y0==y1)break;int e2=2*e;if(e2>=dy){e+=dy;x0+=sx;}if(e2<=dx){e+=dx;y0+=sy;}}}
static void fill(uint16_t*f,int w,int h,uint16_t c){for(int i=0;i<w*h;i++)f[i]=c;}
static void rect(uint16_t*f,int w,int h,int x0,int y0,int x1,int y1,uint16_t c){for(int y=y0;y<=y1;y++)for(int x=x0;x<=x1;x++)px(f,w,h,x,y,c);}
static void circ(uint16_t*f,int w,int h,int cx,int cy,int r,uint16_t c){int x=r,y=0,e=0;while(x>=y){int p[8][2]={{x,y},{y,x},{-y,x},{-x,y},{-x,-y},{-y,-x},{y,-x},{x,-y},{x,-y}};for(int i=0;i<8;i++)px(f,w,h,cx+p[i][0],cy+p[i][1],c);y++;if(e<=0)e+=2*y+1;if(e>0){x--;e-=2*x+1;}}}
static void radial(uint16_t*f,int w,int h,float deg,int r0,int r1,uint16_t c){float a=(deg-90)*M_PI/180.0f;int cx=w/2,cy=h/2;ln(f,w,h,cx+(int)(cosf(a)*r0),cy+(int)(sinf(a)*r0),cx+(int)(cosf(a)*r1),cy+(int)(sinf(a)*r1),c);}
static void box(uint16_t*f,int w,int h,int x0,int y0,int x1,int y1,uint16_t c){ln(f,w,h,x0,y0,x1,y0,c);ln(f,w,h,x1,y0,x1,y1,c);ln(f,w,h,x1,y1,x0,y1,c);ln(f,w,h,x0,y1,x0,y0,c);}
static void invalid_x(uint16_t*f,int w,int h,int x0,int y0,int x1,int y1){for(int d=-3;d<=3;d++){ln(f,w,h,x0+d,y0,x1+d,y1,RED);ln(f,w,h,x1+d,y0,x0+d,y1,RED);}}
static void invalid(uint16_t*f,int w,int h){invalid_x(f,w,h,95,95,w-96,h-96);}

/* Tiny 3x5 uppercase test font, deliberately limited to test-overlay characters. */
static const char *glyph(char c){
    switch(c){
    case 'A':return"010101111101101";case 'B':return"110101110101110";case 'D':return"110101101101110";
    case 'E':return"111100110100111";case 'F':return"111100110100100";case 'G':return"011100101101011";
    case 'I':return"111010010010111";case 'K':return"101101110101101";case 'L':return"100100100100111";
    case 'M':return"101111111101101";case 'N':return"101111111111101";case 'O':return"010101101101010";
    case 'P':return"110101110100100";case 'R':return"110101110101101";case 'S':return"011100010001110";
    case 'T':return"111010010010010";case 'U':return"101101101101111";case 'V':return"101101101101010";
    case 'W':return"101101111111101";case 'Y':return"101101010010010";case '+':return"000010111010000";
    case '-':return"000000111000000";case '/':return"001001010100100";case ':':return"000010000010000";
    case '0':return"111101101101111";case '1':return"010110010010111";case '2':return"110001111100111";
    case '3':return"110001111001110";case '4':return"101101111001001";case '5':return"111100110001110";
    case '6':return"011100111101111";case '7':return"111001010010010";case '8':return"111101111101111";
    case '9':return"111101111001110";default:return"000000000000000";}
}
static void text(uint16_t*f,int w,int h,int x,int y,const char*s,int scale,uint16_t c){for(;*s;s++,x+=4*scale){const char*g=glyph(*s);for(int yy=0;yy<5;yy++)for(int xx=0;xx<3;xx++)if(g[yy*3+xx]=='1')rect(f,w,h,x+xx*scale,y+yy*scale,x+(xx+1)*scale-1,y+(yy+1)*scale-1,c);}}
static void num(uint16_t*f,int w,int h,int x,int y,int n,int scale,uint16_t c){char b[12];int p=11;b[p]=0;if(n==0)b[--p]='0';else{bool neg=n<0;if(neg)n=-n;while(n&&p)b[--p]=(char)('0'+n%10),n/=10;if(neg)b[--p]='-';}text(f,w,h,x,y,&b[p],scale,c);}

static void sim_marker(uint16_t*f,int w,int h){const int x=202,y=h-32,s=2;rect(f,w,h,x-7,y-6,x+80,y+25,RED);text(f,w,h,x,y,"SIM",4,WHITE);(void)s;}

static void altimeter(uint16_t*f,int w,int h,const instrument_ui_t*u,const instrument_data_t*d){fill(f,w,h,BLACK);int r=w/2-24;for(int k=0;k<3;k++)circ(f,w,h,w/2,h/2,r-k,WHITE);for(int i=0;i<50;i++)radial(f,w,h,i*7.2f,r-(i%5?12:28),r,WHITE);if(d->altitude_valid){int a=d->altitude_ft<0?0:d->altitude_ft;radial(f,w,h,(a%1000)*.36f,18,r-38,WHITE);radial(f,w,h,(a%10000)*.036f,18,r-72,WHITE);radial(f,w,h,(a%100000)*.0036f,18,r-112,WHITE);}else invalid(f,w,h);box(f,w,h,162,350,318,398,u->settings_active?YELLOW:GREY);for(int i=0;i<5;i++)ln(f,w,h,177,374+i,303,374+i,WHITE);if(u->settings_active)for(int k=0;k<2;k++)circ(f,w,h,w/2,h/2,r-8-k,YELLOW);}
static void compass(uint16_t*f,int w,int h,const instrument_ui_t*u,const instrument_data_t*d){fill(f,w,h,BLACK);int r=w/2-25;for(int k=0;k<3;k++)circ(f,w,h,w/2,h/2,r-k,WHITE);float hdg=d->heading_valid?(float)d->heading_deg:0.0f;for(int i=0;i<72;i++){float bearing=i*5.0f-hdg;radial(f,w,h,bearing,r-(i%2?10:(i%6?18:30)),r,WHITE);}ln(f,w,h,w/2,18,w/2-13,48,YELLOW);ln(f,w,h,w/2,18,w/2+13,48,YELLOW);ln(f,w,h,w/2-13,48,w/2+13,48,YELLOW);ln(f,w,h,w/2,170,w/2,310,YELLOW);ln(f,w,h,165,245,315,245,YELLOW);ln(f,w,h,205,305,w/2,280,YELLOW);ln(f,w,h,275,305,w/2,280,YELLOW);radial(f,w,h,(float)u->heading_bug_deg-hdg,r-38,r-8,YELLOW);if(!d->heading_valid)invalid(f,w,h);if(u->settings_active)for(int k=0;k<2;k++)circ(f,w,h,w/2,h/2,r-8-k,YELLOW);}

static void test_overlay(uint16_t*f,int w,int h,const instrument_data_t*d){
    if(!d->test_overlay)return;
    rect(f,w,h,70,4,410,70,BLACK);box(f,w,h,70,4,410,70,YELLOW);
    text(f,w,h,96,11,"TEST MODE - ATTITUDE",2,YELLOW);
    num(f,w,h,112,35,d->test_index,2,WHITE);text(f,w,h,132,35,"/",2,WHITE);num(f,w,h,144,35,d->test_count,2,WHITE);
    text(f,w,h,172,35,d->test_name?d->test_name:"TEST",2,WHITE);
    text(f,w,h,110,55,"TIME",1,WHITE);num(f,w,h,130,55,d->test_seconds_left,1,GREEN);text(f,w,h,142,55,"S",1,GREEN);
}

static void pfd(uint16_t*f,int w,int h,const instrument_ui_t*u,const instrument_data_t*d){
    horizon_render_static(f,w,h);
    for(int a=-60;a<=60;a+=10)radial(f,w,h,(float)a,194,(a%30==0)?224:214,WHITE);
    ln(f,w,h,w/2,15,w/2-11,42,YELLOW);ln(f,w,h,w/2,15,w/2+11,42,YELLOW);
    box(f,w,h,362,174,467,306,d->altitude_valid?WHITE:RED);box(f,w,h,146,78,334,110,d->heading_valid?WHITE:RED);
    if(d->heading_valid){text(f,w,h,185,87,"HDG",2,WHITE);num(f,w,h,242,87,d->heading_deg,2,GREEN);}
    if(d->altitude_valid){text(f,w,h,379,184,"ALT",2,WHITE);num(f,w,h,380,215,d->altitude_ft,2,GREEN);}
    if(!d->altitude_valid)invalid_x(f,w,h,370,190,459,290);
    if(!d->heading_valid)invalid_x(f,w,h,157,82,323,106);
    if(!d->attitude_valid)invalid(f,w,h);
    if(u->settings_active)box(f,w,h,155,414,325,458,YELLOW);
    test_overlay(f,w,h,d);
}

void instrument_render(uint16_t*f,int w,int h,const instrument_ui_t*u,const instrument_data_t*d){switch(u->panel){case PANEL_HORIZON:pfd(f,w,h,u,d);break;case PANEL_ALTIMETER:altimeter(f,w,h,u,d);break;case PANEL_COMPASS:compass(f,w,h,u,d);break;default:fill(f,w,h,BLACK);}if(d->simulated)sim_marker(f,w,h);}
