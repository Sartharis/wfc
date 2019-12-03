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
static_assert(sizeof(RGBA) == 4, "");
bool operator==(RGBA x, RGBA y) { return x.r == y.r && x.g == y.g && x.b == y.b && x.a == y.a; }

const auto kInvalidIndex = static_cast<size_t>(-1);

using Image = Array2D<RGBA>;

// ----------------------------------------------------------------------------

class Model
{
public:
	size_t              _width;      // Of output image.
	size_t              _height;     // Of output image.
	size_t              _num_patterns;
	bool                _periodic_out;
	size_t              _foundation = kInvalidIndex; // Index of pattern which is at the base, or kInvalidIndex

	// The weight of each pattern (e.g. how often that pattern occurs in the sample image).
	std::vector<double> _pattern_weight; // num_patterns

	virtual bool propagate(Output* output) const = 0;
	virtual bool on_boundary(int x, int y) const = 0;
	virtual Image image(const Output& output) const = 0;
};


