#include "horizon_renderer.h"

#include <math.h>
#include <stdbool.h>
#include <stdlib.h>

#define RGB565_BLUE   0x259F
#define RGB565_BROWN  0x79E4
#define RGB565_WHITE  0xFFFF
#define RGB565_YELLOW 0xFFE0
#define RGB565_BLACK  0x0000

#define PITCH_PIXELS_PER_DEG 6.8f

static void put_pixel(uint16_t *fb, int w, int h, int x, int y, uint16_t c)
{
    if ((unsigned)x < (unsigned)w && (unsigned)y < (unsigned)h) fb[y*w+x]=c;
}

static void line(uint16_t *fb,int w,int h,int x0,int y0,int x1,int y1,uint16_t c)
{
    int dx=abs(x1-x0),sx=x0<x1?1:-1,dy=-abs(y1-y0),sy=y0<y1?1:-1,e=dx+dy;
    for(;;){put_pixel(fb,w,h,x0,y0,c);if(x0==x1&&y0==y1)break;int e2=2*e;if(e2>=dy){e+=dy;x0+=sx;}if(e2<=dx){e+=dx;y0+=sy;}}
}

static void thick_line(uint16_t *fb,int w,int h,int x0,int y0,int x1,int y1,uint16_t c,int thickness)
{
    float dx=(float)(x1-x0),dy=(float)(y1-y0),len=sqrtf(dx*dx+dy*dy);
    float nx=len>0?-dy/len:0,ny=len>0?dx/len:1;
    for(int i=-thickness/2;i<=thickness/2;i++)line(fb,w,h,x0+(int)lroundf(nx*i),y0+(int)lroundf(ny*i),x1+(int)lroundf(nx*i),y1+(int)lroundf(ny*i),c);
}

static void world_to_screen(float wx,float wy,float roll_rad,float pitch_px,int cx,int cy,int *sx,int *sy)
{
    float c=cosf(roll_rad),s=sinf(roll_rad);
    float y=wy+pitch_px;
    *sx=cx+(int)lroundf(wx*c+y*s);
    *sy=cy+(int)lroundf(-wx*s+y*c);
}

static void pitch_mark(uint16_t *fb,int w,int h,float roll,float pitch_px,int cx,int cy,int deg)
{
    const float wy=-(float)deg*PITCH_PIXELS_PER_DEG;
    const bool major=(abs(deg)%10)==0;
    const int half=major?66:38;
    const int gap=major?18:12;
    int x0,y0,x1,y1;
    world_to_screen(-half,wy,roll,pitch_px,cx,cy,&x0,&y0);
    world_to_screen(-gap,wy,roll,pitch_px,cx,cy,&x1,&y1);
    thick_line(fb,w,h,x0,y0,x1,y1,RGB565_WHITE,major?3:2);
    world_to_screen(gap,wy,roll,pitch_px,cx,cy,&x0,&y0);
    world_to_screen(half,wy,roll,pitch_px,cx,cy,&x1,&y1);
    thick_line(fb,w,h,x0,y0,x1,y1,RGB565_WHITE,major?3:2);
}

static void bank_tick(uint16_t *fb,int w,int h,int cx,int cy,float deg,int inner,int outer,int thickness)
{
    const float a=(deg-90.0f)*(float)M_PI/180.0f;
    const int x0=cx+(int)lroundf(cosf(a)*inner),y0=cy+(int)lroundf(sinf(a)*inner);
    const int x1=cx+(int)lroundf(cosf(a)*outer),y1=cy+(int)lroundf(sinf(a)*outer);
    thick_line(fb,w,h,x0,y0,x1,y1,RGB565_WHITE,thickness);
}

static void bank_scale(uint16_t *fb,int w,int h,int cx,int cy,float roll_deg)
{
    /* Fixed conventional bank scale: 10, 20, 30, 45 and 60 degrees each side. */
    static const int marks[]={10,20,30,45,60};
    for(unsigned i=0;i<sizeof(marks)/sizeof(marks[0]);i++){
        const int d=marks[i];
        const bool major=(d==30||d==60);
        bank_tick(fb,w,h,cx,cy,-d,major?177:183,202,major?4:3);
        bank_tick(fb,w,h,cx,cy, d,major?177:183,202,major?4:3);
    }
    bank_tick(fb,w,h,cx,cy,0,172,202,4);

    /* Moving white roll pointer. Positive/right bank moves clockwise. */
    const float a=(roll_deg-90.0f)*(float)M_PI/180.0f;
    const float ux=cosf(a),uy=sinf(a),vx=-uy,vy=ux;
    const int tipx=cx+(int)lroundf(ux*169),tipy=cy+(int)lroundf(uy*169);
    const int basex=cx+(int)lroundf(ux*150),basey=cy+(int)lroundf(uy*150);
    const int x1=basex+(int)lroundf(vx*9),y1=basey+(int)lroundf(vy*9);
    const int x2=basex-(int)lroundf(vx*9),y2=basey-(int)lroundf(vy*9);
    thick_line(fb,w,h,tipx,tipy,x1,y1,RGB565_BLACK,7);
    thick_line(fb,w,h,x1,y1,x2,y2,RGB565_BLACK,7);
    thick_line(fb,w,h,x2,y2,tipx,tipy,RGB565_BLACK,7);
    thick_line(fb,w,h,tipx,tipy,x1,y1,RGB565_WHITE,3);
    thick_line(fb,w,h,x1,y1,x2,y2,RGB565_WHITE,3);
    thick_line(fb,w,h,x2,y2,tipx,tipy,RGB565_WHITE,3);
}

void horizon_render(uint16_t *fb,int width,int height,float pitch_deg,float roll_deg)
{
    const int cx=width/2,cy=height/2;
    const float roll=roll_deg*(float)M_PI/180.0f;
    const float pitch_px=pitch_deg*PITCH_PIXELS_PER_DEG;
    const float c=cosf(roll),s=sinf(roll);

    for(int y=0;y<height;y++)for(int x=0;x<width;x++){
        float dx=(float)(x-cx),dy=(float)(y-cy);
        float world_y=dx*s+dy*c-pitch_px;
        fb[y*width+x]=(world_y<0)?RGB565_BLUE:RGB565_BROWN;
    }

    int x0,y0,x1,y1;
    world_to_screen(-360,0,roll,pitch_px,cx,cy,&x0,&y0);
    world_to_screen(360,0,roll,pitch_px,cx,cy,&x1,&y1);
    thick_line(fb,width,height,x0,y0,x1,y1,RGB565_WHITE,4);

    for(int deg=-20;deg<=20;deg+=5){if(deg!=0)pitch_mark(fb,width,height,roll,pitch_px,cx,cy,deg);}

    bank_scale(fb,width,height,cx,cy,roll_deg);

    /* Fixed aircraft reference. Accepted attitude mathematics are unchanged:
       the sphere moves around this symbol; the symbol never follows pitch/bank. */
    thick_line(fb,width,height,cx-92,cy,cx-24,cy,RGB565_BLACK,9);
    thick_line(fb,width,height,cx+24,cy,cx+92,cy,RGB565_BLACK,9);
    thick_line(fb,width,height,cx-92,cy,cx-24,cy,RGB565_YELLOW,5);
    thick_line(fb,width,height,cx+24,cy,cx+92,cy,RGB565_YELLOW,5);
    thick_line(fb,width,height,cx-24,cy,cx-10,cy+13,RGB565_BLACK,9);
    thick_line(fb,width,height,cx+24,cy,cx+10,cy+13,RGB565_BLACK,9);
    thick_line(fb,width,height,cx-24,cy,cx-10,cy+13,RGB565_YELLOW,5);
    thick_line(fb,width,height,cx+24,cy,cx+10,cy+13,RGB565_YELLOW,5);
    thick_line(fb,width,height,cx-10,cy+13,cx+10,cy+13,RGB565_YELLOW,5);

    for(int d=-5;d<=5;d++){put_pixel(fb,width,height,cx+d,cy,RGB565_BLACK);put_pixel(fb,width,height,cx,cy+d,RGB565_BLACK);}
}
