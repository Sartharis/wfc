#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <memory>
#include <vector>

#include <stb_image.h>
#include <stb_image_write.h>

#include "arrays.hpp"


struct RGBA
{
	uint8_t r, g, b, a;
};


// ----------------------------------------------------------------------------

class Model
{
public:
	size_t              _width;      // Of output image.
	size_t              _height;     // Of output image.
	size_t              _num_patterns;
	bool                _periodic_out;
	size_t              _foundation; // Index of pattern which is at the base

	// The weight of each pattern (e.g. how often that pattern occurs in the sample image).
	std::vector<double> _pattern_weight; // num_patterns

	virtual bool propagate(Output* output) const;
	virtual bool on_boundary(int x, int y) const;
	virtual Array2D<RGBA> image(const Output& output) const;
};


