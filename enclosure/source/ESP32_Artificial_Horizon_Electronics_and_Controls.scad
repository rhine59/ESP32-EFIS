// ESP32 Artificial Horizon — electronics, control and rear-service hardware
// Supplementary/non-primary flight-development instrument
// Units: mm
// This source complements ESP32_Artificial_Horizon_Flight_Development_Case.scad.
// Verify all purchased hardware against the CAD before final printing.

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
// The reference encoder is Bourns PEC09-2320F-T0015 (9 mm class, push switch,
// M7 x 0.75 bushing, nominal 7.2 mm panel hole). The pod remains parametric.
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
encoder_front_wall   = 2.0;

// -----------------------------
// Electronics carrier
// -----------------------------
electronics_carrier_d   = 70.0;
electronics_carrier_t   = 2.5;
electronics_mount_pcd   = 60.0;
electronics_mount_hole_d = 2.7; // M2.5 clearance

// ESP32-S3-DevKitC-1 reference envelope.
// Use envelope/edge retention rather than guessed board hole locations.
esp32_board_x = 25.8;
esp32_board_y = 62.8;
esp32_clearance = 0.6;
esp32_pocket_x = esp32_board_x + esp32_clearance;
esp32_pocket_y = esp32_board_y + esp32_clearance;
esp32_rail_w   = 1.8;
esp32_rail_h   = 2.5;
esp32_pocket_depth = 0.8;

// Adafruit TPS61169 PID 6354 reference envelope: 25.2 x 19.0 x 10.1 mm.
// Mounting uses slots/ties rather than guessed hole positions.
tps_board_x = 25.2;
tps_board_y = 19.0;
tps_center_y = 12.0;

// Generic MCP23008 / small carrier PCB zone. Exact board is not frozen.
proto_zone_x = 25.0;
proto_zone_y = 18.0;
proto_center_y = -12.0;

tie_slot_w = 3.0;
tie_slot_l = 8.0;

// -----------------------------
// Rear cover internal standoffs
// -----------------------------
electronics_standoff_pcd = electronics_mount_pcd;
electronics_standoff_d   = 6.0;
electronics_standoff_h   = 10.0;
electronics_standoff_pilot_d = 2.0; // M2.5 insert/tap pilot

// -----------------------------
// USB-C cable strain relief
// -----------------------------
// The slot clears a compact right-angle USB-C plug; this clamp grips the cable
// jacket so vibration is not carried by the ESP32 USB connector.
usb_clamp_center_y = -31.0;
usb_clamp_hole_pitch = 16.0;
usb_clamp_hole_d = 3.2;       // M3 clearance
usb_clamp_x = 22.0;
usb_clamp_y = 12.0;
usb_clamp_z = 4.0;
usb_cable_d = 5.0;            // starting value; tune to actual cable jacket

module tie_slot(x,y,rot=0) {
    translate([x,y,-0.1]) rotate([0,0,rot])
        hull() {
            translate([-tie_slot_l/2+tie_slot_w/2,0,0]) cylinder(d=tie_slot_w,h=electronics_carrier_t+0.2);
            translate([ tie_slot_l/2-tie_slot_w/2,0,0]) cylinder(d=tie_slot_w,h=electronics_carrier_t+0.2);
        }
}

module front_bezel_with_encoder() {
    difference() {
        union() {
            // Main annular bezel.
            difference() {
                cylinder(d=bezel_od, h=bezel_t);
                translate([0,0,-0.1]) cylinder(d=bezel_id, h=bezel_t+0.2);
            }

            // Existing locating spigot for the optical window seat.
            translate([0,0,bezel_t])
                difference() {
                    cylinder(d=bezel_spigot_d, h=bezel_spigot_h);
                    translate([0,0,-0.1]) cylinder(d=bezel_id, h=bezel_spigot_h+0.2);
                }

            // Compact control pod sits entirely on the cockpit side of the panel.
            // This avoids requiring an extra notch in the aircraft panel cutout.
            translate([-encoder_pod_x/2, encoder_pod_center_y-encoder_pod_y/2, 0])
                cube([encoder_pod_x, encoder_pod_y, encoder_pod_depth]);
        }

        // Four original bezel retaining screws.
        for (a=[0,90,180,270]) {
            x=(bezel_screw_circle_d/2)*cos(a);
            y=(bezel_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=bezel_screw_d, h=bezel_t+bezel_spigot_h+0.3);
        }

        // Encoder body pocket opens from the rear of the pod.
        translate([-encoder_body_x/2, encoder_pod_center_y-encoder_body_y/2, -0.1])
            cube([encoder_body_x, encoder_body_y, encoder_body_depth+0.1]);

        // M7 bushing / 7.2 mm panel aperture through the remaining front wall.
        translate([0,encoder_pod_center_y,encoder_body_depth-0.05])
            cylinder(d=encoder_panel_hole_d, h=encoder_pod_depth-encoder_body_depth+0.2);
    }
}

module electronics_carrier() {
    difference() {
        union() {
            cylinder(d=electronics_carrier_d, h=electronics_carrier_t);

            // ESP32 side rails on one face. USB end is intentionally open at -Y.
            translate([-esp32_pocket_x/2-esp32_rail_w, -esp32_pocket_y/2, electronics_carrier_t])
                cube([esp32_rail_w, esp32_pocket_y, esp32_rail_h]);
            translate([ esp32_pocket_x/2, -esp32_pocket_y/2, electronics_carrier_t])
                cube([esp32_rail_w, esp32_pocket_y, esp32_rail_h]);
            translate([-esp32_pocket_x/2, esp32_pocket_y/2-esp32_rail_w, electronics_carrier_t])
                cube([esp32_pocket_x, esp32_rail_w, esp32_rail_h]);
        }

        // M2.5 carrier mount holes.
        for (a=[45,135,225,315]) {
            x=(electronics_mount_pcd/2)*cos(a);
            y=(electronics_mount_pcd/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=electronics_mount_hole_d,h=electronics_carrier_t+0.2);
        }

        // Shallow ESP32 locating pocket. It establishes position without loading components.
        translate([-esp32_pocket_x/2,-esp32_pocket_y/2,electronics_carrier_t-esp32_pocket_depth])
            cube([esp32_pocket_x,esp32_pocket_y,esp32_pocket_depth+0.1]);

        // USB connector/cable escape at -Y end.
        translate([-7,-electronics_carrier_d/2-0.1,-0.1])
            cube([14,10,electronics_carrier_t+esp32_rail_h+0.2]);

        // TPS61169 tie-slot pairs. Intended for the face opposite the ESP32.
        for (x=[-tps_board_x/2-2.0,tps_board_x/2+2.0])
            tie_slot(x,tps_center_y,90);

        // MCP23008 / prototype-board tie-slot pairs.
        for (x=[-proto_zone_x/2-2.0,proto_zone_x/2+2.0])
            tie_slot(x,proto_center_y,90);

        // Four additional harness tie points near the quadrants.
        tie_slot(-23,0,90);
        tie_slot( 23,0,90);
        tie_slot(0, 24,0);
        tie_slot(0,-24,0);
    }
}

module rear_cover_service() {
    difference() {
        union() {
            cylinder(d=cover_flange_d, h=cover_t);
            translate([0,0,cover_t]) cylinder(d=cover_spigot_d, h=rear_lip_h);

            // Four internal standoffs carry the removable electronics plate.
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

        // Existing rear-cover retaining screw pattern.
        for (a=[45,135,225,315]) {
            x=(rear_screw_circle_d/2)*cos(a);
            y=(rear_screw_circle_d/2)*sin(a);
            translate([x,y,-0.1]) cylinder(d=rear_screw_d,h=cover_t+rear_lip_h+0.3);
        }

        // Existing right-angle USB-C / cable service slot.
        translate([-usb_slot_w/2,-cover_flange_d/2-0.1,0.8])
            cube([usb_slot_w,usb_slot_h+2,cover_t+rear_lip_h]);

        // Two M3 holes for the external cable-jacket clamp.
        for (x=[-usb_clamp_hole_pitch/2,usb_clamp_hole_pitch/2])
            translate([x,usb_clamp_center_y,-0.1])
                cylinder(d=usb_clamp_hole_d,h=cover_t+rear_lip_h+0.3);
    }
}

module usb_strain_relief_clamp() {
    difference() {
        translate([-usb_clamp_x/2,-usb_clamp_y/2,0])
            cube([usb_clamp_x,usb_clamp_y,usb_clamp_z]);

        // M3 fastener clearances.
        for (x=[-usb_clamp_hole_pitch/2,usb_clamp_hole_pitch/2])
            translate([x,0,-0.1]) cylinder(d=usb_clamp_hole_d,h=usb_clamp_z+0.2);

        // Half-round cable groove on underside. Tune usb_cable_d to the actual cable.
        translate([0,0,0]) rotate([90,0,0])
            cylinder(d=usb_cable_d,h=usb_clamp_y+0.4,center=true);
    }
}

// FRONT_BEZEL_CONTROL, ELECTRONICS_CARRIER, REAR_COVER_SERVICE, USB_CLAMP
part = "ELECTRONICS_CARRIER";
if (part == "FRONT_BEZEL_CONTROL") front_bezel_with_encoder();
if (part == "ELECTRONICS_CARRIER") electronics_carrier();
if (part == "REAR_COVER_SERVICE") rear_cover_service();
if (part == "USB_CLAMP") usb_strain_relief_clamp();
