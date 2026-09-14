// ESP32 Artificial Horizon — flight-development enclosure
// NOT a certified/approved primary flight instrument enclosure.
// Units: mm
// Verify the actual insert manufacturer's dimensions before final printing.

$fn = 64;

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

// M5 brass threaded insert recesses at the back of the enclosure.
// Intended for heat-set / press-fit threaded inserts accepting M5 cap-head screws.
// These dimensions are deliberately parametric because M5 insert outside diameters vary by manufacturer.
m5_insert_circle_d = 66.0;
m5_insert_boss_d   = 12.0;
m5_insert_boss_h   = 10.0;
m5_insert_recess_d = 7.2;    // starting value only; match purchased insert datasheet
m5_insert_recess_h = 8.0;    // starting value only; match purchased insert length
m5_thread_clearance_d = 5.5; // clearance below insert for M5 screw end

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

module body() {
    difference() {
        union() {
            rounded_square(flange_size, flange_corner, flange_t);
            translate([0,0,flange_t])
                cylinder(d=body_od, h=body_depth-flange_t);
            rear_bosses();
            // Reinforced rear bosses for captive M5 threaded inserts.
            m5_insert_bosses();
        }

        // Front panel through-holes remain aligned with the standard mounting pattern.
        for (x=[-mount_pitch/2, mount_pitch/2])
            for (y=[-mount_pitch/2, mount_pitch/2]) {
                translate([x,y,-0.1])
                    cylinder(d=mount_hole_d, h=flange_t+0.3);

                // Recess opens from the rear face. The M5 brass insert is installed here
                // and accepts an M5 cap-head screw from the rear installation side.
                translate([x,y,body_depth-m5_insert_recess_h])
                    cylinder(d=m5_insert_recess_d, h=m5_insert_recess_h+0.2);
                translate([x,y,flange_t])
                    cylinder(d=m5_thread_clearance_d, h=body_depth-flange_t-m5_insert_recess_h+0.2);
            }

        translate([0,0,-0.1])
            cylinder(d=display_open_d, h=flange_t+display_pocket_depth+0.2);

        translate([-display_pocket_x/2,-display_pocket_y/2,flange_t])
            cube([display_pocket_x, display_pocket_y, display_pocket_depth]);

        translate([0,0,flange_t+display_pocket_depth])
            cylinder(d=rear_open_d, h=body_depth+1);

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

part = "BODY";
if (part == "BODY") body();
if (part == "COVER") rear_cover();
