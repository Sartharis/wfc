#include "arrays.hpp"


export void didChange_ispc(uniform int _width, uniform int _height,
    uniform bool* did_change, uniform int _num_patterns,
    uniform bool _periodic_out, uniform Array3D<Bool> _wave,
    uniform Array2D<Bool> _changes, uniform Array3D<Bool> _propagator)
{
	foreach (x2 = 0 ... _width, y2 = 0 ... _height) {
        for (int d = 0; d < 4; ++d) {
            int x1 = x2, y1 = y2;
            
            // Grab coordinates for given neighbor (periodic assumes pattern 
            // repeats over border)
            if (d == 0) {
                if (x2 == 0) {
                    if (!_periodic_out) { continue; }
                    x1 = _width - 1;
                } else {
                    x1 = x2 - 1;
                }
            } else if (d == 1) {
                if (y2 == _height - 1) {
                    if (!_periodic_out) { continue; }
                    y1 = 0;
                } else {
                    y1 = y2 + 1;
                }
            } else if (d == 2) {
                if (x2 == _width - 1) {
                    if (!_periodic_out) { continue; }
                    x1 = 0;
                } else {
                    x1 = x2 + 1;
                }
            } else {
                if (y2 == 0) {
                    if (!_periodic_out) { continue; }
                    y1 = _height - 1;
                } else {
                    y1 = y2 - 1;
                }
            }

            // If neighbor tile didn't change, skip it
            if (!_changes.get(x1, y1)) { continue; }

            for (int t2 = 0; t2 < _num_patterns; ++t2) {
                // if a pattern in our cell is still possible...
                if (_wave.get(x2, y2, t2)) {
                    // check if the pattern is still valid for some possible
                    // pattern in neighbor
                    bool b = false;
                    for (int t1 = 0; t1 < _num_patterns && !b; ++t1) {
                        if (_wave.get(x1, y1, t1)) {
                            b = _propagator.get(d, t1, t2);
                        }
                    }

                    // ... if not, mark that pattern as impossible
                    if (!b) {
                        _wave.set(x2, y2, t2, false);
                        _changes.set(x2, y2, true);
                        *did_change = true;
                    }
                }
			}
		}
	}
}


