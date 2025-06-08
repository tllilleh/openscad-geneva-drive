include <BOSL2/std.scad>

/* This is a Geneva drive implementation in OpenSCAD.
 *
 * You can find the full library and documentation at: https://github.com/tllilleh/openscad-geneva-drive

 * This library requires the BOSL2 library (https://github.com/BelfrySCAD/BOSL2) to be included.
 *
 * References:
 * - https://en.wikipedia.org/wiki/Geneva_drive
 * - https://hansaehoon.blogspot.com/2018/03/geneva-gearwheel-calculation-and-design_25.html
 * - https://benbrandt22.github.io/genevaGen/
 *
 */

$fn=$preview?64:128;

/* [Hidden] */
TOL = 0.25;
EPS = 0.01;

/* [Geneva Drive] */
geneva_wheel_r = 25;        // .1
geneva_wheel_slots = 5;     // 1
geneva_crank_pin_r = 2.5;   // .1
geneva_clearance = 0.25;    // .05
geneva_h = 5;               // .1
// mutually exclusive with geneva_rounding, if set you need to set geneva_rounding to 0!
geneva_chamfer = 0.5;       // .1
// mutually exclusive with geneva_chamfer, if set you need to set geneva_chamfer to 0!
geneva_rounding = 0.0;      // .1

/* [Base] */
shaft_r = 2.5;              // .1
base_h = 5;                 // .1
base_spacer_h = 1;          // .1

/* Helper functions that clients might need to use as well */
function geneva_center_distance(wheel_r, slots) = wheel_r / cos(180/slots);
function geneva_crank_r(center_distance, wheel_r) = sqrt(pow(center_distance, 2) - pow(wheel_r, 2));

module geneva_wheel(wheel_r, slots, crank_pin_r, h, clearance=0.25, chamfer=undef, rounding=undef, anchor=CENTER, spin=0, orient=UP)
{
    rounding_pos = (is_def(rounding) && rounding != 0) ? rounding : undef;
    rounding_neg = (is_def(rounding) && rounding != 0) ? -rounding : undef;
    chamfer_pos = (is_def(chamfer) && chamfer != 0) ? chamfer : undef;
    chamfer_neg = (is_def(chamfer) && chamfer != 0) ? -chamfer : undef;
    slot_angle = 360/slots;
    crank_pin_d = crank_pin_r * 2;
    center_distance = geneva_center_distance(wheel_r, slots);
    crank_r = geneva_crank_r(center_distance, wheel_r);
    slot_center_length = crank_r + wheel_r - center_distance;
    slot_width = crank_pin_d + clearance;
    stop_arc_r = crank_r - (crank_pin_d * 1.5);

    attachable(anchor, spin, orient, r=wheel_r, l=h, axis=TOP)
    {
        difference()
        {
            // wheel
            cyl(r=wheel_r, h=h, chamfer=chamfer_pos, rounding=rounding_pos);

            // stop arcs
            for (angle = [slot_angle:slot_angle:360])
            {
                zrot(angle)
                    left(center_distance)
                    cyl(r=stop_arc_r, h=h+EPS, chamfer=chamfer_neg, rounding=rounding_neg);
            }

            // slots
            for (angle = [slot_angle/2:slot_angle:360])
            {
                zrot(angle)
                    left(wheel_r)
                    {
                        cyl(r=slot_width/2, h=h+EPS, chamfer=chamfer_neg, rounding=rounding_neg);
                        zrot(90) xrot(90) linear_extrude(height=slot_center_length) projection() xrot(90) cyl(r=slot_width/2, h=h+EPS, chamfer=chamfer_neg, rounding=rounding_neg);
                        right(slot_center_length) cyl(r=slot_width/2, h=h+EPS, chamfer=chamfer_neg, rounding=rounding_neg);
                    }
            }
        }

        children();
    }
}

module geneva_crank(wheel_r, slots, crank_pin_r, h, base_h, clearance=0.25, chamfer=undef, rounding=undef, anchor=CENTER, spin=0, orient=UP)
{
    rounding_pos = (is_def(rounding) && rounding != 0) ? rounding : undef;
    rounding_neg = (is_def(rounding) && rounding != 0) ? -rounding : undef;
    chamfer_pos = (is_def(chamfer) && chamfer != 0) ? chamfer : undef;
    chamfer_neg = (is_def(chamfer) && chamfer != 0) ? -chamfer : undef;
    crank_pin_d = crank_pin_r * 2;
    center_distance = geneva_center_distance(wheel_r, slots);
    crank_r = geneva_crank_r(center_distance, wheel_r);
    stop_arc_r = crank_r - (crank_pin_d * 1.5);
    stop_disc_r = stop_arc_r - clearance;
    clearance_arc = (wheel_r * stop_disc_r) / crank_r;
    clearance_arc_dist = sqrt(pow(stop_disc_r, 2) + pow(clearance_arc, 2));

    attachable(anchor, spin, orient, r=crank_r+crank_pin_r, l=base_h+h, axis=TOP)
    {
        down((base_h+h)/2)
        union()
        {
            // base
            hull()
            {
                cyl(r=stop_disc_r, h=base_h, chamfer=chamfer_pos, rounding=rounding_pos, anchor=BOTTOM);
                right(crank_r) cyl(r=crank_pin_r, h=base_h, chamfer=chamfer_pos, rounding=rounding_pos, anchor=BOTTOM);
            }

            up(base_h/2)
            {
                // stop disk
                difference()
                {
                    cyl(r=stop_disc_r, h=h+base_h/2, chamfer2=chamfer_pos, rounding2=rounding_pos, anchor=BOTTOM);

                    right(clearance_arc_dist)
                        cyl(r=clearance_arc, h=h+base_h/2+EPS, chamfer2=chamfer_neg, rounding2=rounding_neg, anchor=BOTTOM);
                }

                // drive pin
                right(crank_r) cyl(r=crank_pin_r, h=h+base_h/2, chamfer2=chamfer_pos, rounding2=rounding_pos, anchor=BOTTOM);

            }
        }

        children();
    }
}

module my_geneva_wheel(anchor=CENTER, spin=0, orient=UP)
{
    rounding_neg = (is_def(geneva_rounding) && geneva_rounding != 0) ? -geneva_rounding : undef;
    chamfer_neg = (is_def(geneva_chamfer) && geneva_chamfer != 0) ? -geneva_chamfer : undef;

    attachable(anchor, spin, orient, r=geneva_wheel_r, l=geneva_h, axis=TOP)
    {
        difference()
        {
            geneva_wheel(
                    wheel_r = geneva_wheel_r,
                    slots = geneva_wheel_slots,
                    crank_pin_r = geneva_crank_pin_r,
                    h = geneva_h,
                    clearance = geneva_clearance,
                    chamfer = geneva_chamfer,
                    rounding = geneva_rounding
                    );

            cyl(r=shaft_r+TOL, h=geneva_h+EPS, chamfer=chamfer_neg, rounding=rounding_neg);
        }

        children();
    }
}

module my_geneva_crank(anchor=CENTER, spin=0, orient=UP)
{
    rounding_neg = (is_def(geneva_rounding) && geneva_rounding != 0) ? -geneva_rounding : undef;
    chamfer_neg = (is_def(geneva_chamfer) && geneva_chamfer != 0) ? -geneva_chamfer : undef;
    crank_r = geneva_crank_r(geneva_center_distance(geneva_wheel_r, geneva_wheel_slots), geneva_wheel_r);

    attachable(anchor, spin, orient, r=crank_r + geneva_crank_pin_r, l=2*geneva_h, axis=TOP)
    {
        difference()
        {
            geneva_crank(
                    wheel_r = geneva_wheel_r,
                    slots = geneva_wheel_slots,
                    crank_pin_r = geneva_crank_pin_r,
                    h = geneva_h,
                    base_h = geneva_h,
                    clearance = geneva_clearance,
                    chamfer = geneva_chamfer,
                    rounding = geneva_rounding
                    );

            cyl(r=shaft_r+TOL, h=2*geneva_h+EPS, chamfer=chamfer_neg, rounding=rounding_neg);
        }

        children();
    }
}

module base(anchor=CENTER, spin=0, orient=UP)
{
    center_distance = geneva_center_distance(geneva_wheel_r, geneva_wheel_slots);

    attachable(size=[center_distance+2*shaft_r*3, 2*shaft_r*3, base_h], anchor, spin, orient, axis=TOP)
    {
        right(center_distance/2)
        union()
        {
            hull()
            {
                cyl(r=shaft_r*3, h=base_h);

                left(center_distance)
                    cyl(r=shaft_r*3, h=base_h);

            }

            shaft_len = base_spacer_h + 3*geneva_h;

            up(base_h/2)
            {
                cyl(r=shaft_r, h=shaft_len, anchor=BOTTOM);
                cyl(r=shaft_r+2, h=base_spacer_h+geneva_h+geneva_clearance, anchor=BOTTOM);

                left(center_distance)
                {
                    cyl(r=shaft_r, h=shaft_len, anchor=BOTTOM);
                    cyl(r=shaft_r+2, h=base_spacer_h, anchor=BOTTOM);
                }
            }
        }
        children();
    }
}

module plate_1()
{
    center_distance = geneva_center_distance(geneva_wheel_r, geneva_wheel_slots);
    crank_r = geneva_crank_r(center_distance, geneva_wheel_r);

    my_geneva_wheel(anchor=BOTTOM);

    left(geneva_wheel_r + crank_r + 5)
        my_geneva_crank(anchor=BOTTOM);

    fwd(geneva_wheel_r + shaft_r*3 + 5)
        base(anchor=BOTTOM);
}

module assembly()
{
    center_distance = geneva_center_distance(geneva_wheel_r, geneva_wheel_slots);

    base();

    right(center_distance/2)
    up(base_h/2 + base_spacer_h)
    {
        zrot((360/geneva_wheel_slots)/2)
            up(geneva_h+geneva_clearance)
            my_geneva_wheel(anchor=BOTTOM);

        left(center_distance)
            my_geneva_crank(anchor=BOTTOM);
    }
}

module mw_plate_1(){plate_1();}
module mw_assembly_view(){assembly();}

//assembly();
plate_1();
