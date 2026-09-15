#include "horizon_renderer.h"

#include <math.h>

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
    for(int i=-thickness/2;i<=thickness/2;i++)line(fb,w,h,x0+(int)(nx*i),y0+(int)(ny*i),x1+(int)(nx*i),y1+(int)(ny*i),c);
}

static void world_to_screen(float wx,float wy,float roll_rad,float pitch_px,int cx,int cy,int *sx,int *sy)
{
    float c=cosf(roll_rad),s=sinf(roll_rad);
    /* Positive pitch moves the horizon down relative to the fixed aircraft. */
    float y=wy+pitch_px;
    *sx=cx+(int)lroundf(wx*c-y*s);
    *sy=cy+(int)lroundf(wx*s+y*c);
}

void horizon_render(uint16_t *fb,int width,int height,float pitch_deg,float roll_deg)
{
    const int cx=width/2,cy=height/2;
    const float roll=roll_deg*(float)M_PI/180.0f;
    const float pitch_px=pitch_deg*PITCH_PIXELS_PER_DEG;
    const float c=cosf(roll),s=sinf(roll);

    /* Classify every pixel in aircraft-centred coordinates. This gives a true
       moving/rotating sky-ground boundary instead of the previous static split. */
    for(int y=0;y<height;y++)for(int x=0;x<width;x++){
        float dx=(float)(x-cx),dy=(float)(y-cy);
        float world_y=-dx*s+dy*c-pitch_px;
        fb[y*width+x]=(world_y<0)?RGB565_BLUE:RGB565_BROWN;
    }

    /* Moving horizon line. */
    int x0,y0,x1,y1;
    world_to_screen(-360,0,roll,pitch_px,cx,cy,&x0,&y0);
    world_to_screen(360,0,roll,pitch_px,cx,cy,&x1,&y1);
    thick_line(fb,width,height,x0,y0,x1,y1,RGB565_WHITE,5);

    /* Pitch ladder moves and banks with the horizon. 5 degrees = 34 px. */
    for(int deg=-20;deg<=20;deg+=5){if(deg==0)continue;float wy=-(float)deg*PITCH_PIXELS_PER_DEG;int half=(abs(deg)%10)?42:62;world_to_screen(-half,wy,roll,pitch_px,cx,cy,&x0,&y0);world_to_screen(half,wy,roll,pitch_px,cx,cy,&x1,&y1);thick_line(fb,width,height,x0,y0,x1,y1,RGB565_WHITE,2);}

    /* Fixed aircraft symbol: it must never rotate with the horizon. */
    thick_line(fb,width,height,cx-82,cy+26,cx-18,cy+26,RGB565_YELLOW,5);
    thick_line(fb,width,height,cx+18,cy+26,cx+82,cy+26,RGB565_YELLOW,5);
    thick_line(fb,width,height,cx-18,cy+36,cx+18,cy+36,RGB565_YELLOW,5);
    thick_line(fb,width,height,cx,cy+18,cx,cy+38,RGB565_YELLOW,2);

    for(int d=-5;d<=5;d++){put_pixel(fb,width,height,cx+d,cy,RGB565_BLACK);put_pixel(fb,width,height,cx,cy+d,RGB565_BLACK);}
}
