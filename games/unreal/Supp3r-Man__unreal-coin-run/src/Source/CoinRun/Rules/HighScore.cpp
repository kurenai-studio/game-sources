#include "Rules/HighScore.h"

#include <climits>

namespace coinrun {
namespace highscore {

int Parse(const std::string& stored) {
    if (stored.empty()) return 0;
    long long value = 0;
    for (char ch : stored) {
        if (ch < '0' || ch > '9') return 0;
        value = value * 10 + (ch - '0');
        if (value > INT_MAX) return 0;
    }
    return static_cast<int>(value);
}

std::string Format(int score) {
    return std::to_string(score < 0 ? 0 : score);
}

int Update(int best, int score, bool* is_new_best) {
    const bool is_new = score > best;
    if (is_new_best != nullptr) *is_new_best = is_new;
    return is_new ? score : best;
}

}  // namespace highscore
}  // namespace coinrun
