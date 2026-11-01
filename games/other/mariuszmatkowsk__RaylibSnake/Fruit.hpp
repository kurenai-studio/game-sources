#pragma once

#include <ranges>
#include <vector>

#include <raylib.h>
#include <raymath.h>

class Fruit {
public:
    explicit Fruit(Color color, int cell_size, int board_width,
                   int board_height, int offset,
                   const std::vector<Vector2>& occupied_positions)
        : color_(std::move(color)), cell_size_(cell_size),
          board_width_(board_width), board_height_(board_height),
          offset_(offset) {
        next(occupied_positions);
    }

    void draw() {
        Rectangle rectangle{.x = position_.x * cell_size_ + offset_,
                            .y = position_.y * cell_size_ + offset_,
                            .width = static_cast<float>(cell_size_),
                            .height = static_cast<float>(cell_size_)};
        DrawRectangleRounded(rectangle, 1.0, 3, color_);
    }

    Vector2 get_pos() const {
        return position_;
    }

    void next(const std::vector<Vector2>& occupied_positions) {
        position_ = get_random_position();
        while (std::ranges::find(occupied_positions, position_) !=
               std::ranges::end(occupied_positions)) {
            position_ = get_random_position();
        }
    }

private:
    Vector2 get_random_position() const {
        return Vector2{
            .x = static_cast<float>(GetRandomValue(0, board_width_ - 1)),
            .y = static_cast<float>(GetRandomValue(0, board_height_ - 1))};
    }

    const Color color_;
    const int cell_size_;
    const int board_width_;
    const int board_height_;
    Vector2 position_;
    const int offset_;
};
