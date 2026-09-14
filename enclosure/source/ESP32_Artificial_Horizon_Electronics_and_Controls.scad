// ESP32 Artificial Horizon — electronics, control and rear-service hardware
// Supplementary/non-primary flight-development instrument
// Units: mm
// Custom ESP32-S3-WROOM-1-N16R2 PCB now mounts directly to rear-cover standoffs.
// Verify all purchased hardware and fabricated PCB dimensions before final printing.

$fn = 96;

// -----------------------------
// Shared enclosure dimensions
// -----------------------------
cover_t         = 3.0;
rear_lip_h      = 3.0;
body_od         = 79.60;
wall            = 3.0;
rear_open_d     = body_od - 2*wall;
cover_clearance = 0.35;
cover_spigot_d  = rear_open_d - 2*cover_clearance;
cover_flange_d  = body_od - 0.8;
rear_screw_circle_d = 66.0;
rear_screw_d    = 3.2;
usb_slot_w      = 13.0;
usb_slot_h      = 7.0;

// -----------------------------
// Front bezel + compact encoder
// -----------------------------
bezel_od             = 70.0;
bezel_id             = 55.0;
bezel_t              = 2.5;
bezel_spigot_h       = 1.5;
bezel_spigot_d       = 62.70;
bezel_screw_circle_d = 67.0;
bezel_screw_d        = 2.2;

encoder_pod_x        = 14.0;
encoder_pod_y        = 14.0;
encoder_pod_depth    = 9.0;
encoder_pod_center_y = -37.0;
encoder_panel_hole_d = 7.2;
encoder_body_x       = 11.5;
encoder_body_y       = 11.5;
encoder_body_depth   = 6.5;

// -----------------------------
// Custom carrier PCB mechanical target
// -----------------------------
// Revision-A target is a 68 mm circular, 1.6 mm PCB mounted directly to the
// rear-cover standoffs. The printed gauge below is for fit/drill validation only.
pcb_d = 68.0;
pcb_t = 1.6;
pcb_mount_pcd = 60.0;
pcb_mount_hole_d = 2.7; // M2.5 clearance

// ESP32-S3-WROOM-1 module reference envelope: 18.0 x 25.5 mm.
// The integrated antenna occupies the end of the module and must be kept clear.
module_x = 18.0;
module_y = 25.5;
module_antenna_y = 6.0;
module_center_y = pcb_d/2 - module_y/2 + 0.5;

// Gauge uses a rectangular opening under the antenna end to represent the
// intended RF keepout/cutout. Final PCB geometry must follow Espressif guidance.
antenna_keepout_x = 18.5;
antenna_keepout_y = 7.0;

// -----------------------------
// Rear cover internal standoffs
// -----------------------------
electronics_standoff_pcd = pcb_mount_pcd;
electronics_standoff_d   = 6.0;
electronics_standoff_h   = 10.0;
electronics_standoff_pilot_d = 2.0; // M2.5 insert/tap pilot

// -----------------------------
// USB-C cable strain relief
// -----------------------------
usb_clamp_center_y = -31.0;
usb_clamp_hole_pitch = 16.0;
usb_clamp_hole_d = 3.2;
usb_clamp_x = 22.0;
usb_clamp_y = 12.0;
usb_clamp_z = 4.0;
usb_cable_d = 5.0;

module front_bezel_with_encoder() {
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
            translate([-encoder_pod_x/2, encoder_pod_center_y-encoder_pod_y/2, 0])
                cube([encoder_pod_x, encoder_pod_y, encoder_pod_depth]);
        }

        for (a=[0,90,180,270]) {
            x=(bezel_screw_circle_d/2)*cos(a);
            y=(bezel_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=bezel_screw_d, h=bezel_t+bezel_spigot_h+0.3);
        }

        translate([-encoder_body_x/2, encoder_pod_center_y-encoder_body_y/2, -0.1])
            cube([encoder_body_x, encoder_body_y, encoder_body_depth+0.1]);

        translate([0,encoder_pod_center_y,encoder_body_depth-0.05])
            cylinder(d=encoder_panel_hole_d, h=encoder_pod_depth-encoder_body_depth+0.2);
    }
}

module pcb_fit_gauge() {
    difference() {
        cylinder(d=pcb_d, h=pcb_t);

        // Four M2.5-class mounting holes on the same 60 mm PCD as the rear cover.
        for (a=[45,135,225,315]) {
            x=(pcb_mount_pcd/2)*cos(a);
            y=(pcb_mount_pcd/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=pcb_mount_hole_d,h=pcb_t+0.2);
        }

        // RF antenna keepout/cutout at 12 o'clock.
        translate([-antenna_keepout_x/2, pcb_d/2-antenna_keepout_y, -0.1])
            cube([antenna_keepout_x, antenna_keepout_y+0.2, pcb_t+0.2]);

        // Small USB alignment notch at 6 o'clock for rear-cover slot checks.
        translate([-usb_slot_w/2,-pcb_d/2-0.1,-0.1])
            cube([usb_slot_w,5.0,pcb_t+0.2]);
    }
}

module rear_cover_service() {
    difference() {
        union() {
            cylinder(d=cover_flange_d, h=cover_t);
            translate([0,0,cover_t]) cylinder(d=cover_spigot_d, h=rear_lip_h);

            for (a=[45,135,225,315]) {
                x=(electronics_standoff_pcd/2)*cos(a);
                y=(electronics_standoff_pcd/2)*sin(a);
                translate([x,y,cover_t+rear_lip_h])
                    difference() {
                        cylinder(d=electronics_standoff_d,h=electronics_standoff_h);
                        cylinder(d=electronics_standoff_pilot_d,h=electronics_standoff_h+0.2);
                    }
            }
        }

        for (a=[45,135,225,315]) {
            x=(rear_screw_circle_d/2)*cos(a);
            y=(rear_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=rear_screw_d,h=cover_t+rear_lip_h+0.3);
        }

        translate([-usb_slot_w/2,-cover_flange_d/2-0.1,0.8])
            cube([usb_slot_w,usb_slot_h+2,cover_t+rear_lip_h]);

        for (x=[-usb_clamp_hole_pitch/2,usb_clamp_hole_pitch/2])
            translate([x,usb_clamp_center_y,-0.1])
                cylinder(d=usb_clamp_hole_d,h=cover_t+rear_lip_h+0.3);
    }
}

module usb_strain_relief_clamp() {
    difference() {
        translate([-usb_clamp_x/2,-usb_clamp_y/2,0])
            cube([usb_clamp_x,usb_clamp_y,usb_clamp_z]);

        for (x=[-usb_clamp_hole_pitch/2,usb_clamp_hole_pitch/2])
            translate([x,0,-0.1]) cylinder(d=usb_clamp_hole_d,h=usb_clamp_z+0.2);

        translate([0,0,0]) rotate([90,0,0])
            cylinder(d=usb_cable_d,h=usb_clamp_y+0.4,center=true);
    }
}

// FRONT_BEZEL_CONTROL, PCB_FIT_GAUGE, REAR_COVER_SERVICE, USB_CLAMP
part = "PCB_FIT_GAUGE";
if (part == "FRONT_BEZEL_CONTROL") front_bezel_with_encoder();
if (part == "PCB_FIT_GAUGE") pcb_fit_gauge();
if (part == "REAR_COVER_SERVICE") rear_cover_service();
if (part == "USB_CLAMP") usb_strain_relief_clamp();
