// The radiator bot's stock and its fits for an FDM print, as a module: every part the bot prints
// reads its clearances from here, so a printer that runs fat or lean is answered in one place.
//
// Everything is printed but the drill rod and the dowel pins the gears turn on, so the fits below
// are an FDM printer's.

unit mm

// == Fits for an FDM print =======================================================================
run := 0.35mm                   // a printed bore turning on drill rod, over the rod
press := 0.05mm                 // a printed hole a rod is pressed into (drill or ream to fit)
gap := 0.3mm                    // between printed faces that meet or pass
bond := 0.25mm                  // a compound's pieces run into one another, so they print as one
wall := 2.4mm                   // six 0.4 mm perimeters
boss_wall := 2 * wall           // a post's wall round a rod pressed into it
slip := 0.15mm                  // a glued joint's printed faces, apart each side
snug := 0.05mm                  // a printed part pressed into a printed one, apart each side: a
                                // light press as an FDM print comes out (its outsides print a
                                // little fat and its insides a little lean); sand to fit

// == Printed gears ===============================================================================
pa := 20deg                     // every gear's pressure angle (a helical gear's, normal)
thin := 0.15mm                  // each gear's teeth thinned: 0.3 mm backlash a mesh
chamfer := 0.4mm                // each gear's tips chamfered at both faces, 45deg

// == Screws ======================================================================================
pilot := 2.5mm                  // an M3 screw's self-tapping hole in a print
m3_clear := 3.4mm
m3_head_d := 5.6mm              // an M3 pan head (ISO 7045, and a self-tapper's), across and tall
m3_head_h := 2.4mm
m4_clear := 4.6mm
m4_nut_af := 7.3mm              // an M4 nut's pocket across the flats
