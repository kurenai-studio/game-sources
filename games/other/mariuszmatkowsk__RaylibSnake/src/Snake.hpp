#pragma once

#include <raylib.h>
#include <raymath.h>

#include <deque>
#include <ranges>
#include <vector>

class Snake {
public:
    Snake(Color color, int cell_size, int board_width, int board_height,
          int offset)
        : color_(std::move(color)), cell_size_(cell_size),
          board_width_(board_width), board_height_(board_height),
          direction_(Vector2{.x = 1, .y = 0}), should_add_segment_(false),
          direction_blocked_(true), offset_(offset) {
        init_snake();
    }

    void draw() {
        for (const auto cell : body_) {
            Rectangle rectangle{.x = cell.x * cell_size_ + offset_,
                                .y = cell.y * cell_size_ + offset_,
                                .width = static_cast<float>(cell_size_),
                                .height = static_cast<float>(cell_size_)};
            DrawRectangleRounded(rectangle, 0.7, 3, color_);
        }
    }

    void move_up() {
        if (direction_.y != 1 && !direction_blocked_) {
            direction_ = Vector2{.x = 0, .y = -1};
            direction_blocked_ = true;
        }
    }

    void move_down() {
        if (direction_.y != -1 && !direction_blocked_) {
            direction_ = Vector2{.x = 0, .y = 1};
            direction_blocked_ = true;
        }
    }

    void move_left() {
        if (direction_.x != 1 && !direction_blocked_) {
            direction_ = Vector2{.x = -1, .y = 0};
            direction_blocked_ = true;
        }
    }

    void move_right() {
        if (direction_.x != -1 && !direction_blocked_) {
            direction_ = Vector2{.x = 1, .y = 0};
            direction_blocked_ = true;
        }
    }

    Vector2 get_direction() const {
        return direction_;
    }

    bool can_eat_food(Vector2 fruit_pos) const {
        return get_head_pos() == fruit_pos;
    }

    void eat_food() {
        should_add_segment_ = true;
    }

    void update() {
        body_.push_front(Vector2Add(body_.front(), direction_));
        if (should_add_segment_) {
            // handle eat fruit
            should_add_segment_ = false;
        } else {
            // move snake
            body_.pop_back();
        }
        direction_blocked_ = false;
    }

    bool is_collision() const {
        return is_collision_with_edges() || is_collision_with_self();
    }

    std::vector<Vector2> get_occupied_positions() const {
        return {body_.begin(), body_.end()};
    }

    void reset() {
        body_.clear();
        direction_ = Vector2{.x = 1, .y = 0};
        should_add_segment_ = false;
        direction_blocked_ = true;
        init_snake();
    }

private:
    void init_snake() {
        body_.emplace_back(8, 5);
        body_.emplace_back(7, 5);
        body_.emplace_back(6, 5);
    }

    Vector2 get_head_pos() const {
        return body_.front();
    }

    bool is_collision_with_edges() const {
        const auto& head = body_.front();
        return head.x == board_width_ || head.x == -1 ||
               head.y == board_height_ || head.y == -1;
    }

    bool is_collision_with_self() const {
        // check if head has same position are other body segments
        return std::ranges::find(body_ | std::views::drop(1), body_.front()) !=
               std::ranges::end(body_);
    }

    const Color color_;
    const int cell_size_;
    const int board_width_;
    const int board_height_;
    std::deque<Vector2> body_;
    Vector2 direction_;
    bool should_add_segment_;
    bool direction_blocked_;
    const int offset_;
};
