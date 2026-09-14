// ESP32 Artificial Horizon — supplementary/non-primary flight instrument enclosure
// Units: mm
// Current revision adds removable display and BMI088 internal carriers.
// Verify purchased hardware dimensions against physical parts before final printing.

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
window_d             = 62.0;
window_t             = 2.0;
window_radial_clear  = 0.25;
window_seat_d        = window_d + 2*window_radial_clear;
window_seat_depth    = 2.25;
window_visible_d     = 55.0;

// Removable front retaining bezel
bezel_od             = 70.0;
bezel_id             = 55.0;
bezel_t              = 2.5;
bezel_spigot_h       = 1.5;
bezel_spigot_d       = window_seat_d + 0.20;
bezel_screw_circle_d = 67.0;
bezel_screw_d        = 2.2;
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

// Internal display carrier
// Four body bosses support a removable annular carrier immediately behind the LCD.
display_carrier_od = 67.0;
display_carrier_id = 49.0;    // large central opening leaves FFC/thermal clearance
display_carrier_t  = 2.5;
display_carrier_pcd = 64.0;
display_carrier_screw_d = 2.7; // M2.5 clearance
display_carrier_boss_d = 6.0;
display_carrier_boss_h = 7.0;
display_carrier_z = flange_t + display_pocket_depth; // front face location inside body

// Thin compliant pads/gasket are intended between carrier and LCD perimeter.
display_pad_land = 3.0;

// BMI088 Shuttle Board 3.0 nominal envelope from Bosch documentation
bmi_board_x = 22.0;
bmi_board_y = 14.0;
bmi_board_t = 1.6;
bmi_overall_h = 6.7;

// Rigid removable IMU cradle. It clamps the board by its edges; no guessed mounting-hole pattern.
imu_tray_x = 28.0;
imu_tray_y = 20.0;
imu_tray_t = 2.5;
imu_pocket_x = 22.4;
imu_pocket_y = 14.4;
imu_pocket_depth = 1.8;
imu_rail_w = 2.0;
imu_stop_h = 3.0;
imu_mount_pitch = 32.0;
imu_mount_hole_d = 2.7;        // M2.5 clearance
imu_body_boss_d = 6.0;
imu_body_boss_h = 8.0;
imu_mount_z = 30.0;            // measured from instrument front face

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
                cylinder(d=1.6, h=bezel_boss_h+0.2);
            }
    }
}

module display_carrier_body_bosses() {
    for (a=[45,135,225,315]) {
        x=(display_carrier_pcd/2)*cos(a);
        y=(display_carrier_pcd/2)*sin(a);
        translate([x,y,display_carrier_z])
            difference() {
                cylinder(d=display_carrier_boss_d, h=display_carrier_boss_h);
                cylinder(d=2.0, h=display_carrier_boss_h+0.2); // M2.5 insert/tap pilot
            }
    }
}

module imu_body_bosses() {
    // Two bosses provide a rigid, repeatable datum for the separate IMU cradle.
    for (x=[-imu_mount_pitch/2, imu_mount_pitch/2])
        translate([x,0,imu_mount_z])
            difference() {
                cylinder(d=imu_body_boss_d, h=imu_body_boss_h);
                cylinder(d=2.0, h=imu_body_boss_h+0.2);
            }
}

module body() {
    difference() {
        union() {
            rounded_square(flange_size, flange_corner, flange_t);
            translate([0,0,flange_t]) cylinder(d=body_od, h=body_depth-flange_t);
            rear_bosses();
            m5_insert_bosses();
            front_bezel_bosses();
            display_carrier_body_bosses();
            imu_body_bosses();
        }

        for (x=[-mount_pitch/2, mount_pitch/2])
            for (y=[-mount_pitch/2, mount_pitch/2]) {
                translate([x,y,-0.1]) cylinder(d=mount_hole_d, h=flange_t+0.3);
                translate([x,y,body_depth-m5_insert_recess_h]) cylinder(d=m5_insert_recess_d, h=m5_insert_recess_h+0.2);
                translate([x,y,flange_t]) cylinder(d=m5_thread_clearance_d, h=body_depth-flange_t-m5_insert_recess_h+0.2);
            }

        translate([0,0,-0.1]) cylinder(d=window_seat_d, h=window_seat_depth+0.1);
        translate([0,0,window_seat_depth-0.05]) cylinder(d=window_visible_d, h=flange_t-window_seat_depth+display_pocket_depth+0.3);

        translate([-display_pocket_x/2,-display_pocket_y/2,flange_t])
            cube([display_pocket_x, display_pocket_y, display_pocket_depth]);

        translate([0,0,flange_t+display_pocket_depth])
            cylinder(d=rear_open_d, h=body_depth+1);

        for (a=[0,90,180,270]) {
            x=(bezel_screw_circle_d/2)*cos(a);
            y=(bezel_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=2.2, h=1.8);
        }

        translate([-index_notch_w/2, flange_size/2-index_notch_d, -0.1])
            cube([index_notch_w,index_notch_d+0.2,1.0]);
    }
}

module front_bezel() {
    difference() {
        union() {
            difference() {
                cylinder(d=bezel_od, h=bezel_t);
                translate([0,0,-0.1]) cylinder(d=bezel_id, h=bezel_t+0.2);
            }
            translate([0,0,bezel_t])
                difference() {
                    cylinder(d=bezel_spigot_d, h=bezel_spigot_h);
                    translate([0,0,-0.1]) cylinder(d=bezel_id, h=bezel_spigot_h+0.2);
                }
        }
        for (a=[0,90,180,270]) {
            x=(bezel_screw_circle_d/2)*cos(a);
            y=(bezel_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=bezel_screw_d, h=bezel_t+bezel_spigot_h+0.3);
        }
    }
}

module display_carrier() {
    difference() {
        union() {
            // Annular retention plate supports only the display perimeter.
            difference() {
                cylinder(d=display_carrier_od, h=display_carrier_t);
                translate([0,0,-0.1]) cylinder(d=display_carrier_id, h=display_carrier_t+0.2);
            }
            // Four shallow anti-shift pads aligned with the rectangular LCD envelope.
            for (x=[-display_pocket_x/2-display_pad_land/2, display_pocket_x/2+display_pad_land/2])
                translate([x,0,0]) cube([display_pad_land,20,display_carrier_t], center=true);
        }
        for (a=[45,135,225,315]) {
            x=(display_carrier_pcd/2)*cos(a);
            y=(display_carrier_pcd/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=display_carrier_screw_d, h=display_carrier_t+0.2);
        }
        // FFC escape at the lower edge; widened to avoid bending the display tail sharply.
        translate([-8,-display_carrier_od/2-0.1,-0.1]) cube([16,10,display_carrier_t+0.2]);
    }
}

module imu_carrier() {
    difference() {
        union() {
            // Main rigid tray.
            translate([-imu_tray_x/2,-imu_tray_y/2,0]) cube([imu_tray_x,imu_tray_y,imu_tray_t]);
            // Edge rails retain the 22 x 14 mm BMI088 Shuttle Board without relying on unknown hole spacing.
            translate([-imu_tray_x/2,-imu_pocket_y/2,imu_tray_t]) cube([imu_rail_w,imu_pocket_y,imu_stop_h]);
            translate([imu_tray_x/2-imu_rail_w,-imu_pocket_y/2,imu_tray_t]) cube([imu_rail_w,imu_pocket_y,imu_stop_h]);
            translate([-imu_pocket_x/2,imu_pocket_y/2-imu_rail_w,imu_tray_t]) cube([imu_pocket_x,imu_rail_w,imu_stop_h]);
        }

        // Shallow PCB pocket establishes a repeatable mechanical plane.
        translate([-imu_pocket_x/2,-imu_pocket_y/2,imu_tray_t-imu_pocket_depth])
            cube([imu_pocket_x,imu_pocket_y,imu_pocket_depth+0.1]);

        // Two M2.5 body mounting holes.
        for (x=[-imu_mount_pitch/2, imu_mount_pitch/2])
            translate([x,0,-0.1]) cylinder(d=imu_mount_hole_d, h=imu_tray_t+0.2);

        // Connector/wire relief at the open end.
        translate([-6,-imu_tray_y/2-0.1,-0.1]) cube([12,4,imu_tray_t+imu_stop_h+0.2]);
    }
}

module rear_cover() {
    difference() {
        union() {
            cylinder(d=cover_flange_d, h=cover_t);
            translate([0,0,cover_t]) cylinder(d=cover_spigot_d, h=rear_lip_h);
        }
        for (a=[45,135,225,315]) {
            x=(rear_screw_circle_d/2)*cos(a);
            y=(rear_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=rear_screw_d, h=cover_t+rear_lip_h+0.3);
        }
        translate([-usb_slot_w/2, -cover_flange_d/2-0.1, 0.8]) cube([usb_slot_w, usb_slot_h+2, cover_t+rear_lip_h]);
    }
}

// BODY, FRONT_BEZEL, DISPLAY_CARRIER, IMU_CARRIER or COVER
part = "BODY";
if (part == "BODY") body();
if (part == "FRONT_BEZEL") front_bezel();
if (part == "DISPLAY_CARRIER") display_carrier();
if (part == "IMU_CARRIER") imu_carrier();
if (part == "COVER") rear_cover();
