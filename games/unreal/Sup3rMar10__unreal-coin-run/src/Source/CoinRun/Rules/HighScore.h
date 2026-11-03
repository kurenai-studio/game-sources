#pragma once

#include <string>

namespace coinrun {

// Parsing and comparing the stored best score. Storage itself (the config file) lives in the Unreal layer.
namespace highscore {

// Anything missing, malformed, negative or larger than INT_MAX reads as 0.
int Parse(const std::string& stored);

std::string Format(int score);

// Returns the new best; *is_new_best (may be null) is true only for a strictly higher score.
int Update(int best, int score, bool* is_new_best);

}  // namespace highscore
}  // namespace coinrun
