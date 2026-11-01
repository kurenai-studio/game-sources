#include <vector>
#include <array>

using namespace std;


enum Type {
    PAWN,
    ROOK,
    BISHOP,
    KNIGHT,
    QUEEN,
    KING,
    NOTYPE
};

enum Colors {
    PWHITE,
    PBLACK,
    NOCOL,
};

enum Special {
    NONE,
    ATTACK,
    START
};

class Piece {
    public:
        int type;
        int color;
        vector<array<int,2>> offsets; // {x,y} added onto the piece
        vector<array<int,3>> specoffsets; // {x,y,type}
        bool status;
        
        int timesmoved = 0;
        
        vector<int> pos = {0,0};
        
        Piece(int t, int c, vector<array<int,2>> v1 , vector<array<int,3>> v2 , vector<int> v3) {
            type = t;
            color = c;
            offsets = v1;
            specoffsets = v2;
            pos = v3;
            status = true; // alive
        }
};

Piece pmake(int index,vector<int> pos) {
    switch (index) {
        case 0:
            return Piece(PAWN,PWHITE,{{0,-1}},{{-1,-1,ATTACK},{1,-1,ATTACK},{0,-2,START}},pos);
            break;
        case 1:
            return Piece(PAWN,PBLACK,{{0,1}},{{1,1,ATTACK},{-1,1,ATTACK},{0,2,START}},pos);
            break;
        case 2:
            return Piece(ROOK,PWHITE, 
            {{0,1},{0,-1},{1,0},{-1,0},
            {0,2},{0,-2},{2,0},{-2,0},
            {0,3},{0,-3},{3,0},{-3,0},
            {0,4},{0,-4},{4,0},{-4,0},
            {0,5},{0,-5},{5,0},{-5,0},
            {0,6},{0,-6},{6,0},{-6,0},
            {0,7},{0,-7},{7,0},{-7,0}},{{0,0,NONE}},pos);
            break;
        case 3:
            return Piece(ROOK,PBLACK, 
            {{0,1},{0,-1},{1,0},{-1,0},
            {0,2},{0,-2},{2,0},{-2,0},
            {0,3},{0,-3},{3,0},{-3,0},
            {0,4},{0,-4},{4,0},{-4,0},
            {0,5},{0,-5},{5,0},{-5,0},
            {0,6},{0,-6},{6,0},{-6,0},
            {0,7},{0,-7},{7,0},{-7,0}},{{0,0,NONE}},pos);
            break;
        case 4:
            return Piece(BISHOP,PWHITE,{
            {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 7},
            {-1, 1}, {-2, 2}, {-3, 3}, {-4, 4}, {-5, 5}, {-6, 6}, {-7, 7},
            {1, -1}, {2, -2}, {3, -3}, {4, -4}, {5, -5}, {6, -6}, {7, -7},
            {-1, -1}, {-2, -2}, {-3, -3}, {-4, -4}, {-5, -5}, {-6, -6}, {-7, -7}},{{0,0,NONE}},pos);
            break;
        case 5:
            return Piece(BISHOP,PBLACK,{
            {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 7},
            {-1, 1}, {-2, 2}, {-3, 3}, {-4, 4}, {-5, 5}, {-6, 6}, {-7, 7},
            {1, -1}, {2, -2}, {3, -3}, {4, -4}, {5, -5}, {6, -6}, {7, -7},
            {-1, -1}, {-2, -2}, {-3, -3}, {-4, -4}, {-5, -5}, {-6, -6}, {-7, -7}},{{0,0,NONE}},pos);
            break;
        case 6:
            return Piece(KNIGHT,PWHITE,{{-2, -1},{-2,  1},{-1, -2},{-1,  2},
            { 1, -2},{ 1,  2},{ 2, -1},{ 2,  1}},{{0,0,NONE}},pos);
            break;
        case 7:
            return Piece(KNIGHT,PBLACK,{{-2, -1},{-2,  1},{-1, -2},{-1,  2},
            { 1, -2},{ 1,  2},{ 2, -1},{ 2,  1}},{{0,0,NONE}},pos);
            break;
        case 8:
            return Piece(QUEEN,PWHITE, {
            {-7, 0}, {-6, 0}, {-5, 0}, {-4, 0}, {-3, 0}, {-2, 0}, {-1, 0},
            { 1, 0}, { 2, 0}, { 3, 0}, { 4, 0}, { 5, 0}, { 6, 0}, { 7, 0},
            { 0,-7}, { 0,-6}, { 0,-5}, { 0,-4}, { 0,-3}, { 0,-2}, { 0,-1},
            { 0, 1}, { 0, 2}, { 0, 3}, { 0, 4}, { 0, 5}, { 0, 6}, { 0, 7},
            {-7,-7}, {-6,-6}, {-5,-5}, {-4,-4}, {-3,-3}, {-2,-2}, {-1,-1},
            { 1, 1}, { 2, 2}, { 3, 3}, { 4, 4}, { 5, 5}, { 6, 6}, { 7, 7},
            {-7, 7}, {-6, 6}, {-5, 5}, {-4, 4}, {-3, 3}, {-2, 2}, {-1, 1},
            { 1,-1}, { 2,-2}, { 3,-3}, { 4,-4}, { 5,-5}, { 6,-6}, { 7,-7}},{{0,0,NONE}},pos);
            break;
        case 9:
            return Piece(QUEEN,PBLACK, {
            {-7, 0}, {-6, 0}, {-5, 0}, {-4, 0}, {-3, 0}, {-2, 0}, {-1, 0},
            { 1, 0}, { 2, 0}, { 3, 0}, { 4, 0}, { 5, 0}, { 6, 0}, { 7, 0},
            { 0,-7}, { 0,-6}, { 0,-5}, { 0,-4}, { 0,-3}, { 0,-2}, { 0,-1},
            { 0, 1}, { 0, 2}, { 0, 3}, { 0, 4}, { 0, 5}, { 0, 6}, { 0, 7},
            {-7,-7}, {-6,-6}, {-5,-5}, {-4,-4}, {-3,-3}, {-2,-2}, {-1,-1},
            { 1, 1}, { 2, 2}, { 3, 3}, { 4, 4}, { 5, 5}, { 6, 6}, { 7, 7},
            {-7, 7}, {-6, 6}, {-5, 5}, {-4, 4}, {-3, 3}, {-2, 2}, {-1, 1},
            { 1,-1}, { 2,-2}, { 3,-3}, { 4,-4}, { 5,-5}, { 6,-6}, { 7,-7}},{{0,0,NONE}},pos);
            break;
        case 10:
            return Piece(KING,PWHITE, {{-1, -1},{-1,  0},{-1,  1},{ 0, -1},
            { 0,  1},{ 1, -1},{ 1,  0},{ 1,  1}},{{0,0,NONE}},pos);
        case 11:
            return Piece(KING,PBLACK, {{-1, -1},{-1,  0},{-1,  1},{ 0, -1},
            { 0,  1},{ 1, -1},{ 1,  0},{ 1,  1}},{{0,0,NONE}},pos);
    }
    
    return Piece(NOTYPE,NOCOL,{{0,0}},{{0,0,NONE}},pos);
}

vector<Piece> setup() {
    vector<Piece> retvec;
    
    retvec.push_back(pmake(99,{-1,-1}));
    
    //pawns
    retvec.push_back(pmake(0,{0,6}));
    retvec.push_back(pmake(0,{1,6}));
    retvec.push_back(pmake(0,{2,6}));
    retvec.push_back(pmake(0,{3,6}));
    retvec.push_back(pmake(0,{4,6}));
    retvec.push_back(pmake(0,{5,6}));
    retvec.push_back(pmake(0,{6,6}));
    retvec.push_back(pmake(0,{7,6}));
    
    retvec.push_back(pmake(1,{0,1}));
    retvec.push_back(pmake(1,{1,1}));
    retvec.push_back(pmake(1,{2,1}));
    retvec.push_back(pmake(1,{3,1}));
    retvec.push_back(pmake(1,{4,1}));
    retvec.push_back(pmake(1,{5,1}));
    retvec.push_back(pmake(1,{6,1}));
    retvec.push_back(pmake(1,{7,1}));
    
    //rooks
    
    retvec.push_back(pmake(2,{0,7}));
    retvec.push_back(pmake(2,{7,7}));
    
    retvec.push_back(pmake(3,{0,0}));
    retvec.push_back(pmake(3,{7,0}));
    
    //bishops
    
    retvec.push_back(pmake(4,{2,7}));
    retvec.push_back(pmake(4,{5,7}));
    
    retvec.push_back(pmake(5,{2,0}));
    retvec.push_back(pmake(5,{5,0}));
    
    //knights
    
    retvec.push_back(pmake(6,{1,7}));
    retvec.push_back(pmake(6,{6,7}));
    
    retvec.push_back(pmake(7,{1,0}));
    retvec.push_back(pmake(7,{6,0}));
    
    //queens
    
    retvec.push_back(pmake(8,{3,7}));
    retvec.push_back(pmake(9,{3,0}));
    
    //kings
    
    retvec.push_back(pmake(10,{4,7}));
    retvec.push_back(pmake(11,{4,0}));
    
    return retvec;
    
}
