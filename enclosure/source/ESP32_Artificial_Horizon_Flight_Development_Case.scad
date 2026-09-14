// ESP32 Artificial Horizon — supplementary/non-primary flight instrument enclosure
// Units: mm
// Current revision adds a 2.0 mm hard-coated anti-reflective optical window and removable front bezel.
// Verify purchased window thickness and final aircraft installation before use.

$fn = 96;

// Standard 3-1/8 in instrument fit
panel_cutout_d = 80.30;
body_od        = 79.60;
flange_size    = 88.0;
flange_corner  = 5.0;
flange_t       = 4.0;

// Conventional four-hole mounting pattern
mount_pitch    = 62.90;
mount_hole_d   = 4.40;

// Display / internal envelope
display_open_d = 53.6;
display_pocket_x = 58.6;
display_pocket_y = 61.2;
display_pocket_depth = 3.2;

// Optical front window — hard-coated AR polycarbonate target
window_d             = 62.0;   // target disc diameter; confirm with supplier before final print
window_t             = 2.0;    // optical window thickness
window_radial_clear  = 0.25;   // per side
window_seat_d        = window_d + 2*window_radial_clear;
window_seat_depth    = 2.25;   // allows window + thin perimeter gasket
window_visible_d     = 55.0;   // clear visible opening; slightly larger than LCD active area
window_support_width = 2.5;    // minimum annular support land

// Removable front retaining bezel
bezel_od             = 70.0;
bezel_id             = 55.0;
bezel_t              = 2.5;
bezel_spigot_h       = 1.5;
bezel_spigot_d       = window_seat_d + 0.20;
bezel_screw_circle_d = 67.0;
bezel_screw_d        = 2.2;    // M2 clearance
bezel_boss_d         = 5.5;
bezel_boss_h         = 5.0;

wall           = 3.0;
body_depth     = 58.0;
rear_lip_h     = 3.0;
rear_open_d    = body_od - 2*wall;

// Rear cover
cover_t        = 3.0;
cover_clearance = 0.35;
cover_spigot_d = rear_open_d - 2*cover_clearance;
cover_flange_d = body_od - 0.8;

// Rear cover retaining screws
rear_screw_circle_d = 66.0;
rear_screw_d = 3.2;
rear_boss_d  = 7.5;
rear_boss_h  = 8.0;

// M5 brass threaded insert recesses
m5_insert_boss_d   = 12.0;
m5_insert_boss_h   = 10.0;
m5_insert_recess_d = 7.2;
m5_insert_recess_h = 8.0;
m5_thread_clearance_d = 5.5;

// Cable opening in rear cover
usb_slot_w = 13.0;
usb_slot_h = 7.0;

index_notch_w = 4.0;
index_notch_d = 1.2;

module rounded_square(size, r, h) {
    linear_extrude(height=h)
        offset(r=r)
            square([size-2*r, size-2*r], center=true);
}

module rear_bosses() {
    for (a=[45,135,225,315]) {
        x=(rear_screw_circle_d/2)*cos(a);
        y=(rear_screw_circle_d/2)*sin(a);
        translate([x,y,body_depth-rear_boss_h])
            difference() {
                cylinder(d=rear_boss_d, h=rear_boss_h);
                cylinder(d=2.5, h=rear_boss_h+0.2);
            }
    }
}

module m5_insert_bosses() {
    for (x=[-mount_pitch/2, mount_pitch/2])
        for (y=[-mount_pitch/2, mount_pitch/2])
            translate([x,y,body_depth-m5_insert_boss_h])
                cylinder(d=m5_insert_boss_d, h=m5_insert_boss_h);
}

module front_bezel_bosses() {
    for (a=[0,90,180,270]) {
        x=(bezel_screw_circle_d/2)*cos(a);
        y=(bezel_screw_circle_d/2)*sin(a);
        translate([x,y,0])
            difference() {
                cylinder(d=bezel_boss_d, h=bezel_boss_h);
                cylinder(d=1.6, h=bezel_boss_h+0.2); // pilot for M2 insert/tap
            }
    }
}

module body() {
    difference() {
        union() {
            rounded_square(flange_size, flange_corner, flange_t);
            translate([0,0,flange_t])
                cylinder(d=body_od, h=body_depth-flange_t);
            rear_bosses();
            m5_insert_bosses();
            front_bezel_bosses();
        }

        // Standard panel through-holes + M5 rear insert bores
        for (x=[-mount_pitch/2, mount_pitch/2])
            for (y=[-mount_pitch/2, mount_pitch/2]) {
                translate([x,y,-0.1])
                    cylinder(d=mount_hole_d, h=flange_t+0.3);
                translate([x,y,body_depth-m5_insert_recess_h])
                    cylinder(d=m5_insert_recess_d, h=m5_insert_recess_h+0.2);
                translate([x,y,flange_t])
                    cylinder(d=m5_thread_clearance_d, h=body_depth-flange_t-m5_insert_recess_h+0.2);
            }

        // Optical window pocket from front face.
        translate([0,0,-0.1])
            cylinder(d=window_seat_d, h=window_seat_depth+0.1);

        // Visible opening through front flange behind the protective window.
        translate([0,0,window_seat_depth-0.05])
            cylinder(d=window_visible_d, h=flange_t-window_seat_depth+display_pocket_depth+0.3);

        // Rectangular display pocket behind front face
        translate([-display_pocket_x/2,-display_pocket_y/2,flange_t])
            cube([display_pocket_x, display_pocket_y, display_pocket_depth]);

        // Main electronics cavity
        translate([0,0,flange_t+display_pocket_depth])
            cylinder(d=rear_open_d, h=body_depth+1);

        // Front bezel mounting clearance holes
        for (a=[0,90,180,270]) {
            x=(bezel_screw_circle_d/2)*cos(a);
            y=(bezel_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1])
                cylinder(d=2.2, h=1.8);
        }

        translate([-index_notch_w/2, flange_size/2-index_notch_d, -0.1])
            cube([index_notch_w,index_notch_d+0.2,1.0]);
    }
}

module front_bezel() {
    difference() {
        union() {
            // Main retaining ring
            difference() {
                cylinder(d=bezel_od, h=bezel_t);
                translate([0,0,-0.1]) cylinder(d=bezel_id, h=bezel_t+0.2);
            }
            // Shallow locating spigot which centres over window pocket
            translate([0,0,bezel_t])
                difference() {
                    cylinder(d=bezel_spigot_d, h=bezel_spigot_h);
                    translate([0,0,-0.1]) cylinder(d=bezel_id, h=bezel_spigot_h+0.2);
                }
        }

        // Four M2 fastener clearances
        for (a=[0,90,180,270]) {
            x=(bezel_screw_circle_d/2)*cos(a);
            y=(bezel_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1])
                cylinder(d=bezel_screw_d, h=bezel_t+bezel_spigot_h+0.3);
        }
    }
}

module rear_cover() {
    difference() {
        union() {
            cylinder(d=cover_flange_d, h=cover_t);
            translate([0,0,cover_t])
                cylinder(d=cover_spigot_d, h=rear_lip_h);
        }

        for (a=[45,135,225,315]) {
            x=(rear_screw_circle_d/2)*cos(a);
            y=(rear_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1])
                cylinder(d=rear_screw_d, h=cover_t+rear_lip_h+0.3);
        }

        translate([-usb_slot_w/2, -cover_flange_d/2-0.1, 0.8])
            cube([usb_slot_w, usb_slot_h+2, cover_t+rear_lip_h]);
    }
}

// BODY, FRONT_BEZEL or COVER
part = "BODY";
if (part == "BODY") body();
if (part == "FRONT_BEZEL") front_bezel();
if (part == "COVER") rear_cover();
