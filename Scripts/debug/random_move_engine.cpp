#include <chrono>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

static std::vector<std::vector<int>> parse_board(const std::string& line) {
    const std::string key = "\"board\"";
    std::size_t pos = line.find(key);
    if (pos == std::string::npos) {
        throw std::runtime_error("missing board");
    }

    pos = line.find('[', pos);
    if (pos == std::string::npos) {
        throw std::runtime_error("missing board array");
    }

    std::vector<std::vector<int>> board;
    std::vector<int> row;
    int depth = 0;

    for (std::size_t i = pos; i < line.size(); ++i) {
        char c = line[i];
        if (c == '[') {
            ++depth;
            if (depth == 2) {
                row.clear();
            }
            continue;
        }
        if (c == ']') {
            if (depth == 2) {
                board.push_back(row);
                row.clear();
            }
            --depth;
            if (depth == 0) {
                break;
            }
            continue;
        }
        if (depth == 2 && (c == '-' || (c >= '0' && c <= '9'))) {
            int sign = 1;
            if (c == '-') {
                sign = -1;
                ++i;
            }
            int value = 0;
            bool has_digit = false;
            while (i < line.size() && line[i] >= '0' && line[i] <= '9') {
                value = value * 10 + (line[i] - '0');
                has_digit = true;
                ++i;
            }
            if (has_digit) {
                row.push_back(sign * value);
            }
            --i;
        }
    }

    if (board.empty()) {
        throw std::runtime_error("empty board");
    }
    return board;
}

static std::pair<int, int> choose_move(const std::vector<std::vector<int>>& board) {
    std::vector<std::pair<int, int>> empty_cells;
    for (int y = 0; y < static_cast<int>(board.size()); ++y) {
        for (int x = 0; x < static_cast<int>(board[y].size()); ++x) {
            if (board[y][x] == 0) {
                empty_cells.push_back({x, y});
            }
        }
    }

    if (empty_cells.empty()) {
        throw std::runtime_error("No legal moves");
    }

    static std::mt19937 rng(
        static_cast<unsigned int>(
            std::chrono::high_resolution_clock::now().time_since_epoch().count()));
    std::uniform_int_distribution<std::size_t> dist(0, empty_cells.size() - 1);
    return empty_cells[dist(rng)];
}

int main() {
    std::string line;
    while (std::getline(std::cin, line)) {
        try {
            std::vector<std::vector<int>> board = parse_board(line);
            auto [x, y] = choose_move(board);
            std::cout << "{\"x\":" << x
                      << ",\"y\":" << y
                      << ",\"debug\":{\"engine\":\"cpp_random_debug\"}}"
                      << std::endl;
        } catch (const std::exception& exc) {
            std::cout << "{\"error\":\"" << exc.what()
                      << "\",\"debug\":{\"engine\":\"cpp_random_debug\"}}"
                      << std::endl;
        }
    }
    return 0;
}
