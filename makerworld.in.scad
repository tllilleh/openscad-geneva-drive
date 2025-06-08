$fn=$preview?64:128;

/* [Hidden] */
TOL = 0.25;
EPS = 0.01;

/* [Geneva Drive] */
geneva_wheel_r = 25;        // .1
geneva_wheel_slots = 5;     // 1
geneva_crank_pin_r = 2.5;   // .1
geneva_crank_min_base = true;
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

include <geneva-drive.scad>

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

/* Test Code: not included in makerworld.scad */
//assembly();
plate_1();
