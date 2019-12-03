#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <memory>
#include <numeric>
#include <random>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <chrono>

#include <configuru.hpp>
#include <emilib/irange.hpp>
#include <emilib/strprintf.hpp>
#include <loguru.hpp>
#include <stb_image.h>
#include <stb_image_write.h>

#define JO_GIF_HEADER_FILE_ONLY
#include <jo_gif.cpp>

#include "arrays.hpp"

#include <cuda.h>

// ----------------------------------------------------------------------------

bool TileModel::propagate(Output* output) const
{
	bool did_change = false;

	for (int x2 = 0; x2 < _width; ++x2) {
		for (int y2 = 0; y2 < _height; ++y2) {
			for (int d = 0; d < 4; ++d) {
				int x1 = x2, y1 = y2;
				
				// Grab coordinates for given neighbor (periodic assumes pattern repeats over border)
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
				if (!output->_changes.get(x1, y1)) { continue; }

				for (int t2 = 0; t2 < _num_patterns; ++t2) {
					// if a pattern in our cell is still possible...
					if (output->_wave.get(x2, y2, t2)) {
						
						// ... check if the pattern is still valid for some possible pattern in neighbor ...
						bool b = false;
						for (int t1 = 0; t1 < _num_patterns && !b; ++t1) {
							if (output->_wave.get(x1, y1, t1)) {
								b = _propagator.get(d, t1, t2);
							}
						}

						// ... if not, mark that pattern as impossible
						if (!b) {
							output->_wave.set(x2, y2, t2, false);
							output->_changes.set(x2, y2, true);
							did_change = true;
						}
					}
				}
			}
		}
	}

	return did_change;
}

Image TileModel::image(const Output& output) const
{
	Image result(_width * _tile_size, _height * _tile_size, {});

	for (int x = 0; x < _width; ++x) {
		for (int y = 0; y < _height; ++y) {
			double sum = 0;
			for (const auto t : irange(_num_patterns)) {
				if (output._wave.get(x, y, t)) {
					sum += _pattern_weight[t];
				}
			}

			for (int yt = 0; yt < _tile_size; ++yt) {
				for (int xt = 0; xt < _tile_size; ++xt) {
					if (sum == 0) {
						result.set(x * _tile_size + xt, y * _tile_size + yt, RGBA{0, 0, 0, 255});
					} else {
						double r = 0, g = 0, b = 0, a = 0;
						for (int t = 0; t < _num_patterns; ++t) {
							if (output._wave.get(x, y, t)) {
								RGBA c = _tiles[t][xt + yt * _tile_size];
								r += (double)c.r * _pattern_weight[t] / sum;
								g += (double)c.g * _pattern_weight[t] / sum;
								b += (double)c.b * _pattern_weight[t] / sum;
								a += (double)c.a * _pattern_weight[t] / sum;
							}
						}

						result.set(x * _tile_size + xt, y * _tile_size + yt,
						           RGBA{(uint8_t)r, (uint8_t)g, (uint8_t)b, (uint8_t)a});
					}
				}
			}
		}
	}

	return result;
}

// ----------------------------------------------------------------------------


Result find_lowest_entropy(const Model& model, const Output& output, RandomDouble& random_double,
                           int* argminx, int* argminy)
{
	// We actually calculate exp(entropy), i.e. the sum of the weights of the possible patterns

	double min = std::numeric_limits<double>::infinity();

	// Iterate over every cell
	for (int x = 0; x < model._width; ++x) {
		for (int y = 0; y < model._height; ++y) {
			if (model.on_boundary(x, y)) { continue; }

			size_t num_superimposed = 0;
			double entropy = 0;

			//Get total entropy from the number of weighted possibilities
			for (int t = 0; t < model._num_patterns; ++t) {
				if (output._wave.get(x, y, t)) {
					num_superimposed += 1;
					entropy += model._pattern_weight[t];
				}
			}

			// If entropy is 0 / no options available, it means we reached an impossible state
			if (entropy == 0 || num_superimposed == 0) {
				return Result::kFail;
			}

			if (num_superimposed == 1) {
				continue; // Already frozen
			}

			// Add a tie-breaking bias:
			const double noise = 0.5 * random_double();
			entropy += noise;

			if (entropy < min) {
				min = entropy;
				*argminx = x;
				*argminy = y;
			}
		}
	}

	if (min == std::numeric_limits<double>::infinity()) {
		return Result::kSuccess;
	} else {
		return Result::kUnfinished;
	}
}

Result observe(const Model& model, Output* output, RandomDouble& random_double)
{
	int argminx, argminy;

	// Try to find the cell with lowest possible choices for pattern
	const auto result = find_lowest_entropy(model, *output, random_double, &argminx, &argminy);
	if (result != Result::kUnfinished) { return result; }

	// Create a probability distribution from all the possible patterns in the given cell
	std::vector<double> distribution(model._num_patterns);
	for (int t = 0; t < model._num_patterns; ++t) {
		distribution[t] = output->_wave.get(argminx, argminy, t) ? model._pattern_weight[t] : 0;
	}

	// Grab a random weighted pattern and choose a single pattern to use (i.e. collapse the cell)
	size_t r = spin_the_bottle(std::move(distribution), random_double());
	for (int t = 0; t < model._num_patterns; ++t) {
		output->_wave.set(argminx, argminy, t, t == r);
	}

	// Mark the collapsed cell as changed for propagation purposes
	output->_changes.set(argminx, argminy, true);

	return Result::kUnfinished;
}




