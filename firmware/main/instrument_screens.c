#include "instrument_screens.h"
#include "horizon_renderer.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define BLACK 0x0000
#define WHITE 0xFFFF
#define RED 0xF800
#define YELLOW 0xFFE0
#define GREY 0x4208
#define DARK_GREY 0x2104
#define GREEN 0x07E0

static void px(uint16_t *f, int w, int h, int x, int y, uint16_t c) {
  if ((unsigned)x < (unsigned)w && (unsigned)y < (unsigned)h)
    f[y * w + x] = c;
}
static void ln(uint16_t *f, int w, int h, int x0, int y0, int x1, int y1,
               uint16_t c) {
  int dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1, dy = -abs(y1 - y0),
      sy = y0 < y1 ? 1 : -1, e = dx + dy;
  for (;;) {
    px(f, w, h, x0, y0, c);
    if (x0 == x1 && y0 == y1)
      break;
    int e2 = 2 * e;
    if (e2 >= dy) {
      e += dy;
      x0 += sx;
    }
    if (e2 <= dx) {
      e += dx;
      y0 += sy;
    }
  }
}
static void thick_ln(uint16_t *f, int w, int h, int x0, int y0, int x1, int y1,
                     uint16_t c, int t) {
  for (int d = -(t / 2); d <= t / 2; d++) {
    ln(f, w, h, x0 + d, y0, x1 + d, y1, c);
    ln(f, w, h, x0, y0 + d, x1, y1 + d, c);
  }
}
static void fill(uint16_t *f, int w, int h, uint16_t c) {
  for (int i = 0; i < w * h; i++)
    f[i] = c;
}
static void rect(uint16_t *f, int w, int h, int x0, int y0, int x1, int y1,
                 uint16_t c) {
  for (int y = y0; y <= y1; y++)
    for (int x = x0; x <= x1; x++)
      px(f, w, h, x, y, c);
}
static void circ(uint16_t *f, int w, int h, int cx, int cy, int r, uint16_t c) {
  int x = r, y = 0, e = 0;
  while (x >= y) {
    int p[8][2] = {{x, y},   {y, x},   {-y, x}, {-x, y},
                   {-x, -y}, {-y, -x}, {y, -x}, {x, -y}};
    for (int i = 0; i < 8; i++)
      px(f, w, h, cx + p[i][0], cy + p[i][1], c);
    y++;
    if (e <= 0)
      e += 2 * y + 1;
    if (e > 0) {
      x--;
      e -= 2 * x + 1;
    }
  }
}
static void radial(uint16_t *f, int w, int h, float deg, int r0, int r1,
                   uint16_t c) {
  float a = (deg - 90) * M_PI / 180.0f;
  int cx = w / 2, cy = h / 2;
  ln(f, w, h, cx + (int)(cosf(a) * r0), cy + (int)(sinf(a) * r0),
     cx + (int)(cosf(a) * r1), cy + (int)(sinf(a) * r1), c);
}
static void hand(uint16_t *f, int w, int h, float deg, int r, uint16_t c,
                 int t) {
  float a = (deg - 90) * M_PI / 180.0f;
  int cx = w / 2, cy = h / 2;
  int x = cx + (int)(cosf(a) * r), y = cy + (int)(sinf(a) * r);
  thick_ln(f, w, h, cx, cy, x, y, c, t);
}
static void box(uint16_t *f, int w, int h, int x0, int y0, int x1, int y1,
                uint16_t c) {
  ln(f, w, h, x0, y0, x1, y0, c);
  ln(f, w, h, x1, y0, x1, y1, c);
  ln(f, w, h, x1, y1, x0, y1, c);
  ln(f, w, h, x0, y1, x0, y0, c);
}
static void invalid_x(uint16_t *f, int w, int h, int x0, int y0, int x1,
                      int y1) {
  for (int d = -3; d <= 3; d++) {
    ln(f, w, h, x0 + d, y0, x1 + d, y1, RED);
    ln(f, w, h, x1 + d, y0, x0 + d, y1, RED);
  }
}
static const char *glyph(char c) {
  switch (c) {
  case 'A':
    return "010101111101101";
  case 'B':
    return "110101110101110";
  case 'C':
    return "011100100100011";
  case 'D':
    return "110101101101110";
  case 'E':
    return "111100110100111";
  case 'F':
    return "111100110100100";
  case 'G':
    return "011100101101011";
  case 'H':
    return "101101111101101";
  case 'I':
    return "111010010010111";
  case 'K':
    return "101101110101101";
  case 'L':
    return "100100100100111";
  case 'M':
    return "101111111101101";
  case 'N':
    return "101111111111101";
  case 'O':
    return "010101101101010";
  case 'P':
    return "110101110100100";
  case 'Q':
    return "010101101111011";
  case 'R':
    return "110101110101101";
  case 'S':
    return "011100010001110";
  case 'T':
    return "111010010010010";
  case 'U':
    return "101101101101111";
  case 'V':
    return "101101101101010";
  case 'W':
    return "101101111111101";
  case 'Y':
    return "101101010010010";
  case '+':
    return "000010111010000";
  case '-':
    return "000000111000000";
  case '/':
    return "001001010100100";
  case ':':
    return "000010000010000";
  case '0':
    return "111101101101111";
  case '1':
    return "010110010010111";
  case '2':
    return "110001111100111";
  case '3':
    return "110001111001110";
  case '4':
    return "101101111001001";
  case '5':
    return "111100110001110";
  case '6':
    return "011100111101111";
  case '7':
    return "111001010010010";
  case '8':
    return "111101111101111";
  case '9':
    return "111101111001110";
  default:
    return "000000000000000";
  }
}
static void text(uint16_t *f, int w, int h, int x, int y, const char *s,
                 int scale, uint16_t c) {
  for (; *s; s++, x += 4 * scale) {
    const char *g = glyph(*s);
    for (int yy = 0; yy < 5; yy++)
      for (int xx = 0; xx < 3; xx++)
        if (g[yy * 3 + xx] == '1')
          rect(f, w, h, x + xx * scale, y + yy * scale,
               x + (xx + 1) * scale - 1, y + (yy + 1) * scale - 1, c);
  }
}
static void num(uint16_t *f, int w, int h, int x, int y, int n, int scale,
                uint16_t c) {
  char b[12];
  int p = 11;
  b[p] = 0;
  if (n == 0)
    b[--p] = '0';
  else {
    bool neg = n < 0;
    if (neg)
      n = -n;
    while (n && p)
      b[--p] = (char)('0' + n % 10), n /= 10;
    if (neg)
      b[--p] = '-';
  }
  text(f, w, h, x, y, &b[p], scale, c);
}
static void sim_marker(uint16_t *f, int w, int h) {
  rect(f, w, h, 194, h - 38, 286, h - 7, RED);
  box(f, w, h, 192, h - 40, 288, h - 5, BLACK);
  text(f, w, h, 211, h - 32, "SIM", 4, WHITE);
}
static void instrument_bezel(uint16_t *f, int w, int h) {
  int cx = w / 2, cy = h / 2;
  for (int r = 239; r >= 224; r--)
    circ(f, w, h, cx, cy, r, (r > 232) ? DARK_GREY : BLACK);
  for (int k = 0; k < 3; k++)
    circ(f, w, h, cx, cy, 222 - k, WHITE);
  for (int k = 0; k < 3; k++)
    circ(f, w, h, cx, cy, 216 - k, GREY);
}
static void alt_number(uint16_t *f, int w, int h, int value, float deg) {
  float a = (deg - 90) * M_PI / 180.0f;
  int r = 162;
  int x = w / 2 + (int)(cosf(a) * r) - 9;
  int y = h / 2 + (int)(sinf(a) * r) - 10;
  num(f, w, h, x, y, value, 4, WHITE);
}
static void altitude_hatching(uint16_t *f, int w, int h, int altitude_ft) {
  if (altitude_ft <= 10000)
    return;
  int excess = altitude_ft - 10000;
  if (excess > 1000)
    excess = 1000;
  const float start_deg = 240.0f;
  const float sweep_deg = 60.0f * (float)excess / 1000.0f;
  const int cx = w / 2, cy = h / 2, inner = 108, outer = 145;
  for (int y = cy - outer; y <= cy + outer; y++)
    for (int x = cx - outer; x <= cx + outer; x++) {
      int dx = x - cx, dy = y - cy;
      int r2 = dx * dx + dy * dy;
      if (r2 < inner * inner || r2 > outer * outer)
        continue;
      float deg = atan2f((float)dy, (float)dx) * 180.0f / (float)M_PI + 90.0f;
      if (deg < 0)
        deg += 360.0f;
      if (deg >= start_deg && deg <= start_deg + sweep_deg &&
          ((x + y) % 14 + 14) % 14 < 4)
        px(f, w, h, x, y, WHITE);
    }
  radial(f, w, h, start_deg, inner, outer, WHITE);
  radial(f, w, h, start_deg + sweep_deg, inner, outer, WHITE);
}
/*
 * Mechanical-style Kollsman pressure scale at 3 o'clock.
 * Selected QNH remains integer hPa; 1013.25 is a reference datum only.
 */
static void kollsman_scale(uint16_t *f, int w, int h,
                           const instrument_ui_t *u) {
  const float degrees_per_hpa = 2.0f;
  const float centre_deg = 90.0f;
  const float half_window_deg = 8.0f;
  const int cx = w / 2, cy = h / 2;
  const int mask_inner = 124, mask_outer = 204;
  const int label_radius = 151;
  const int tick_inner = 174, tick_outer = 194;

  /* Clear the local dial beneath the pressure scale. */
  for (int y = cy - mask_outer; y <= cy + mask_outer; y++) {
    for (int x = cx - mask_outer; x <= cx + mask_outer; x++) {
      int dx = x - cx, dy = y - cy;
      int r2 = dx * dx + dy * dy;

      if (r2 < mask_inner * mask_inner || r2 > mask_outer * mask_outer)
        continue;

      float deg = atan2f((float)dy, (float)dx) * 180.0f / (float)M_PI + 90.0f;
      if (deg < 0.0f)
        deg += 360.0f;

      if (deg >= centre_deg - half_window_deg &&
          deg <= centre_deg + half_window_deg)
        px(f, w, h, x, y, BLACK);
    }
  }

  /* Moving integer pressure graduations; label every 5 hPa. */
  for (int pressure = 950; pressure <= 1050; pressure++) {
    float deg =
        centre_deg + ((float)pressure - (float)u->qnh_hpa) * degrees_per_hpa;

    if (deg < centre_deg - half_window_deg ||
        deg > centre_deg + half_window_deg)
      continue;

    int major = (pressure % 5) == 0;
    radial(f, w, h, deg, major ? tick_inner - 6 : tick_inner, tick_outer,
           WHITE);

    if (major) {
      float a = (deg - 90.0f) * M_PI / 180.0f;
      int digits = pressure >= 1000 ? 4 : 3;
      int text_width = (digits - 1) * 8 + 6;
      int x = cx + (int)(cosf(a) * label_radius) - text_width / 2;
      int y = cy + (int)(sinf(a) * label_radius) - 5;

      num(f, w, h, x, y, pressure, 2, WHITE);
    }
  }

  /* Exact 1013.25 hPa standard-pressure datum. */
  float std_deg = centre_deg + (1013.25f - (float)u->qnh_hpa) * degrees_per_hpa;

  if (std_deg >= centre_deg - half_window_deg &&
      std_deg <= centre_deg + half_window_deg) {
    float a = (std_deg - 90.0f) * M_PI / 180.0f;
    int x0 = cx + (int)(cosf(a) * (tick_inner - 10));
    int y0 = cy + (int)(sinf(a) * (tick_inner - 10));
    int x1 = cx + (int)(cosf(a) * tick_outer);
    int y1 = cy + (int)(sinf(a) * tick_outer);

    thick_ln(f, w, h, x0, y0, x1, y1, WHITE, 5);
  }

  /* Fixed selected-QNH index at exactly 3 o'clock. */
  uint16_t index_colour = u->settings_active ? YELLOW : WHITE;
  thick_ln(f, w, h, cx + 166, cy, cx + 202, cy, index_colour, 3);
}

static void alt_test_overlay(uint16_t *f, int w, int h,
                             const instrument_data_t *d) {
  if (!d->test_overlay)
    return;
  rect(f, w, h, 96, 78, 384, 136, BLACK);
  box(f, w, h, 96, 78, 384, 136, WHITE);
  text(f, w, h, 132, 85, "TEST MODE - ALT", 2, YELLOW);
  num(f, w, h, 116, 108, d->test_index, 2, WHITE);
  text(f, w, h, 136, 108, "/", 2, WHITE);
  num(f, w, h, 148, 108, d->test_count, 2, WHITE);
  text(f, w, h, 180, 108, d->test_name ? d->test_name : "TEST", 2, WHITE);
  text(f, w, h, 184, 127, "TIME", 1, WHITE);
  num(f, w, h, 208, 127, d->test_seconds_left, 1, GREEN);
  text(f, w, h, 220, 127, "S", 1, GREEN);
}
static void altimeter(uint16_t *f, int w, int h, const instrument_ui_t *u,
                      const instrument_data_t *d) {
  fill(f, w, h, BLACK);
  instrument_bezel(f, w, h);
  int r = 205;
  for (int i = 0; i < 50; i++) {
    int major = (i % 5) == 0;
    radial(f, w, h, i * 7.2f, r - (major ? 28 : 12), r, WHITE);
  }
  for (int n = 0; n < 10; n++)
    alt_number(f, w, h, n, n * 36.0f);
  text(f, w, h, 204, 151, "ALT", 3, WHITE);
  text(f, w, h, 208, 171, "FEET", 2, GREY);
  kollsman_scale(f, w, h, u);
  if (d->altitude_valid) {
    int a = d->altitude_ft < 0 ? 0 : d->altitude_ft;
    altitude_hatching(f, w, h, a);
    hand(f, w, h, (a % 1000) * .36f, 142, WHITE, 3);
    hand(f, w, h, (a % 10000) * .036f, 105, WHITE, 5);
    hand(f, w, h, (a % 100000) * .0036f, 70, WHITE, 7);
    for (int k = 0; k < 8; k++)
      circ(f, w, h, w / 2, h / 2, k, WHITE);
    rect(f, w, h, 154, 292, 326, 337, BLACK);
    box(f, w, h, 154, 292, 326, 337, WHITE);
    num(f, w, h, 174, 302, a, 4, GREEN);
  } else {
    rect(f, w, h, 120, 187, 360, 286, BLACK);
    box(f, w, h, 120, 187, 360, 286, RED);
    invalid_x(f, w, h, 132, 195, 348, 278);
    rect(f, w, h, 142, 211, 338, 255, BLACK);
    text(f, w, h, 151, 220, "ALT FAIL", 5, RED);
  }
  alt_test_overlay(f, w, h, d);
}
static void compass_label(uint16_t *f, int w, int h, const char *s,
                          float bearing, int radius) {
  float a = (bearing - 90.0f) * M_PI / 180.0f;
  int x = w / 2 + (int)(cosf(a) * radius) - 10;
  int y = h / 2 + (int)(sinf(a) * radius) - 10;
  text(f, w, h, x, y, s, 4, WHITE);
}
static void heading_bug(uint16_t *f, int w, int h, float bearing, int radius) {
  float a = (bearing - 90.0f) * M_PI / 180.0f;
  int cx = w / 2, cy = h / 2;
  float ux = cosf(a), uy = sinf(a), vx = -uy, vy = ux;
  int tx = cx + (int)(ux * (radius - 8)), ty = cy + (int)(uy * (radius - 8));
  int bx = cx + (int)(ux * (radius - 34)), by = cy + (int)(uy * (radius - 34));
  int x1 = bx + (int)(vx * 12), y1 = by + (int)(vy * 12);
  int x2 = bx - (int)(vx * 12), y2 = by - (int)(vy * 12);
  thick_ln(f, w, h, tx, ty, x1, y1, YELLOW, 3);
  thick_ln(f, w, h, x1, y1, x2, y2, YELLOW, 3);
  thick_ln(f, w, h, x2, y2, tx, ty, YELLOW, 3);
}
static void compass_test_overlay(uint16_t *f, int w, int h,
                                 const instrument_data_t *d) {
  if (!d->test_overlay)
    return;
  rect(f, w, h, 103, 82, 377, 137, BLACK);
  box(f, w, h, 103, 82, 377, 137, WHITE);
  text(f, w, h, 132, 89, "TEST MODE - HDG", 2, YELLOW);
  num(f, w, h, 118, 112, d->test_index, 2, WHITE);
  text(f, w, h, 138, 112, "/", 2, WHITE);
  num(f, w, h, 150, 112, d->test_count, 2, WHITE);
  text(f, w, h, 182, 112, d->test_name ? d->test_name : "TEST", 2, WHITE);
}
static void compass(uint16_t *f, int w, int h, const instrument_ui_t *u,
                    const instrument_data_t *d) {
  fill(f, w, h, BLACK);
  instrument_bezel(f, w, h);
  int r = w / 2 - 25;
  float hdg = d->heading_valid ? (float)d->heading_deg : 0.0f;
  for (int i = 0; i < 72; i++) {
    float bearing = i * 5.0f - hdg;
    radial(f, w, h, bearing, r - (i % 2 ? 10 : (i % 6 ? 18 : 30)), r, WHITE);
  }
  compass_label(f, w, h, "N", -hdg, 165);
  compass_label(f, w, h, "E", 90.0f - hdg, 165);
  compass_label(f, w, h, "S", 180.0f - hdg, 165);
  compass_label(f, w, h, "W", 270.0f - hdg, 165);
  ln(f, w, h, w / 2, 18, w / 2 - 13, 48, YELLOW);
  ln(f, w, h, w / 2, 18, w / 2 + 13, 48, YELLOW);
  ln(f, w, h, w / 2 - 13, 48, w / 2 + 13, 48, YELLOW);
  heading_bug(f, w, h, (float)u->heading_bug_deg - hdg, r);
  rect(f, w, h, 177, 194, 303, 268, BLACK);
  box(f, w, h, 177, 194, 303, 268, d->heading_valid ? WHITE : RED);
  text(f, w, h, 210, 202, "HDG", 2, WHITE);
  if (d->heading_valid) {
    int h = d->heading_deg % 360;
    if (h < 0)
      h += 360;
    if (h < 10) {
      text(f, w, h, 198, 226, "00", 4, GREEN);
      num(f, w, h, 230, 226, h, 4, GREEN);
    } else if (h < 100) {
      text(f, w, h, 198, 226, "0", 4, GREEN);
      num(f, w, h, 214, 226, h, 4, GREEN);
    } else
      num(f, w, h, 198, 226, h, 4, GREEN);
  } else {
    invalid_x(f, w, h, 185, 201, 295, 260);
    rect(f, w, h, 190, 218, 290, 247, BLACK);
    text(f, w, h, 194, 222, "FAIL", 4, RED);
  }
  if (u->settings_active)
    for (int k = 0; k < 2; k++)
      circ(f, w, h, w / 2, h / 2, r - 8 - k, YELLOW);
  compass_test_overlay(f, w, h, d);
}
static void test_overlay(uint16_t *f, int w, int h,
                         const instrument_data_t *d) {
  if (!d->test_overlay)
    return;
  rect(f, w, h, 103, 94, 377, 154, BLACK);
  box(f, w, h, 103, 94, 377, 154, WHITE);
  text(f, w, h, 126, 101, "TEST MODE - ATTITUDE", 2, YELLOW);
  num(f, w, h, 126, 124, d->test_index, 2, WHITE);
  text(f, w, h, 146, 124, "/", 2, WHITE);
  num(f, w, h, 158, 124, d->test_count, 2, WHITE);
  text(f, w, h, 190, 124, d->test_name ? d->test_name : "TEST", 2, WHITE);
  text(f, w, h, 196, 143, "TIME", 1, WHITE);
  num(f, w, h, 220, 143, d->test_seconds_left, 1, GREEN);
  text(f, w, h, 232, 143, "S", 1, GREEN);
}
static void pfd(uint16_t *f, int w, int h, const instrument_ui_t *u,
                const instrument_data_t *d) {
  if (!d->attitude_valid) {
    fill(f, w, h, BLACK);
    instrument_bezel(f, w, h);
    invalid_x(f, w, h, 82, 82, w - 83, h - 83);
    rect(f, w, h, 102, 198, 378, 282, BLACK);
    box(f, w, h, 102, 198, 378, 282, RED);
    text(f, w, h, 126, 214, "ATT FAIL", 6, RED);
    text(f, w, h, 157, 260, "NO ATTITUDE", 2, WHITE);
    test_overlay(f, w, h, d);
    return;
  }
  horizon_render(f, w, h, d->pitch_deg, d->roll_deg);
  instrument_bezel(f, w, h);
  text(f, w, h, 174, 16, "ATTITUDE", 2, WHITE);
  if (d->heading_valid) {
    rect(f, w, h, 188, 50, 292, 82, BLACK);
    box(f, w, h, 188, 50, 292, 82, WHITE);
    text(f, w, h, 197, 58, "HDG", 2, WHITE);
    num(f, w, h, 237, 55, d->heading_deg, 3, GREEN);
  }
  if (d->altitude_valid) {
    rect(f, w, h, 365, 178, 455, 238, BLACK);
    box(f, w, h, 365, 178, 455, 238, WHITE);
    text(f, w, h, 376, 186, "ALT", 2, WHITE);
    num(f, w, h, 374, 207, d->altitude_ft, 3, GREEN);
  }
  text(f, w, h, 169, 442, "NON PRIMARY", 2, GREY);
  if (u->settings_active) {
    box(f, w, h, 78, 372, 402, 425, YELLOW);
    text(f, w, h, 94, 383, "SETTINGS - TURN / HOLD", 2, YELLOW);
  }
  test_overlay(f, w, h, d);
}
void instrument_render(uint16_t *f, int w, int h, const instrument_ui_t *u,
                       const instrument_data_t *d) {
  if (!f || !u || !d)
    return;
  switch (u->panel) {
  case PANEL_ALTIMETER:
    altimeter(f, w, h, u, d);
    break;
  case PANEL_COMPASS:
    compass(f, w, h, u, d);
    break;
  case PANEL_HORIZON:
  default:
    pfd(f, w, h, u, d);
    break;
  }
  if (d->simulated)
    sim_marker(f, w, h);
}
