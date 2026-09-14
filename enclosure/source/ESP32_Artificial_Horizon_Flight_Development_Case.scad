// ESP32 Artificial Horizon — flight-development enclosure
// NOT a certified/approved primary flight instrument enclosure.
// Units: mm
//
// Geometry is deliberately conservative for a first printable flight-development article.
// Verify against the actual aircraft panel and installed components before flight use.

$fn = 64;

// Standard 3-1/8 in instrument fit
// A practical panel opening is slightly larger than the nominal 3.125 in instrument size.
panel_cutout_d = 80.30;      // target/reference only; measure the actual aircraft panel
body_od        = 79.60;      // ~0.70 mm diametral clearance in an 80.30 mm opening
flange_size    = 88.0;       // square front flange
flange_corner  = 5.0;
flange_t       = 4.0;

// Conventional four-hole mounting pattern
mount_pitch    = 62.90;      // square centre-to-centre
mount_hole_d   = 4.40;       // conventional #6 mounting-hole clearance/template class

// Display / internal envelope
display_open_d = 53.6;       // slightly above 53.28 mm active diameter
display_pocket_x = 58.6;     // clearance around 58.18 mm panel outline
display_pocket_y = 61.2;     // clearance around 60.71 mm panel outline
display_pocket_depth = 3.2;

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
rear_screw_d = 3.2;          // M3 clearance in cover
rear_boss_d  = 7.5;
rear_boss_h  = 8.0;

// Cable opening in rear cover
usb_slot_w = 13.0;
usb_slot_h = 7.0;

// Small anti-rotation / orientation mark
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
                cylinder(d=2.5, h=rear_boss_h+0.2); // pilot for M3 insert/tapping choice
            }
    }
}

module body() {
    difference() {
        union() {
            // Front mounting flange
            rounded_square(flange_size, flange_corner, flange_t);

            // Panel-cutout locating body
            translate([0,0,flange_t])
                cylinder(d=body_od, h=body_depth-flange_t);

            // Rear cover screw bosses
            rear_bosses();
        }

        // Four standard panel mounting holes
        for (x=[-mount_pitch/2, mount_pitch/2])
            for (y=[-mount_pitch/2, mount_pitch/2])
                translate([x,y,-0.1])
                    cylinder(d=mount_hole_d, h=flange_t+0.3);

        // Front visible display aperture
        translate([0,0,-0.1])
            cylinder(d=display_open_d, h=flange_t+display_pocket_depth+0.2);

        // Rectangular display pocket behind front face
        translate([-display_pocket_x/2,-display_pocket_y/2,flange_t])
            cube([display_pocket_x, display_pocket_y, display_pocket_depth]);

        // Main electronics cavity
        translate([0,0,flange_t+display_pocket_depth])
            cylinder(d=rear_open_d, h=body_depth+1);

        // Orientation notch at top edge
        translate([-index_notch_w/2, flange_size/2-index_notch_d, -0.1])
            cube([index_notch_w,index_notch_d+0.2,1.0]);
    }
}

module rear_cover() {
    difference() {
        union() {
            cylinder(d=cover_flange_d, h=cover_t);
            translate([0,0,cover_t])
                cylinder(d=cover_spigot_d, h=rear_lip_h);
        }

        // Four retaining screw clearance holes
        for (a=[45,135,225,315]) {
            x=(rear_screw_circle_d/2)*cos(a);
            y=(rear_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1])
                cylinder(d=rear_screw_d, h=cover_t+rear_lip_h+0.3);
        }

        // USB-C / cable slot; deliberately generous for strain relief
        translate([-usb_slot_w/2, -cover_flange_d/2-0.1, 0.8])
            cube([usb_slot_w, usb_slot_h+2, cover_t+rear_lip_h]);
    }
}

// Render selector. GitHub Actions uses this to generate separate STL files.
part = "BODY";

if (part == "BODY") body();
if (part == "COVER") rear_cover();
