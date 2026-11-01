#include "pieces.hpp"
#include <cstdlib>

using namespace std;

class ChessManager {
    public:
        vector<Piece> plist;
        Piece curcap = pmake(99,{-1,-1});
        
        ChessManager() {
            plist = setup();
        }
        
        
        
        int find(vector<int> pos) {
            
            int index = 0;
            
            for (int i = 1; i < 33; i++) {
                if (plist[i].pos[0] == pos[0] and plist[i].pos[1] == pos[1]) {
                    index = i;
                    break;
                }
            }
            
            return index;
        }
        
        array<int,2> islegal(Piece piece,vector<int> newpos) {
            for (int i = 0; i < piece.offsets.size(); i++) {
                if (piece.offsets[i][0] == (newpos[0] - piece.pos[0]) 
                and piece.offsets[i][1] == (newpos[1] - piece.pos[1])) {

                    if (piece.type == PAWN and plist[find(newpos)].color != NOCOL) {
                        return { 0,0 };
                    }


                    return piece.offsets[i];
                }
            }
            
            
            if (piece.type == PAWN) {
                
                for (int i = 0; i < 3; i++) {
                    
                    
                    if (piece.specoffsets[i][0] == (newpos[0] - piece.pos[0])
                    and piece.specoffsets[i][1] == (newpos[1] - piece.pos[1])) {
                        
                        
                        if (piece.specoffsets[i][2] == START) {
                            

                            if (piece.pos[1] == 1 and piece.color == PBLACK 
                            and plist[find({newpos[0],newpos[1] - 1})].color == NOCOL
                            and plist[find({newpos[0],newpos[1]})].color == NOCOL) {
                                return {0,-2};
                            } else if (piece.pos[1] == 6 and piece.color == PWHITE 
                            and plist[find({ newpos[0],newpos[1] + 1 })].color == NOCOL
                            and plist[find({newpos[0],newpos[1]})].color == NOCOL) {
                                return {0,2};
                            }
                            
                        }
                        
                        if (piece.specoffsets[i][2] == ATTACK) {
                            
                            if (plist[find(newpos)].color == PBLACK and piece.color == PWHITE) {

                                return {piece.specoffsets[i][0], piece.specoffsets[i][1]};
                            } else if (plist[find(newpos)].color == PWHITE and piece.color == PBLACK) {
                                return {piece.specoffsets[i][0], piece.specoffsets[i][1]};
                            }
                            
                            
                        }
                        
                        
                    }
                }
                
                
            }
            
            
            return {0,0};
        }
        
        
        bool checkmove(Piece piece, vector<int> newpos, int turn) {

            if (turn != piece.color) {
                return false;
                //cout << "NOT YOUR PIECE" << endl;
            }
            
            
            int mov[2] = {islegal(piece,newpos)[0],islegal(piece,newpos)[1]};
            
            if (mov[0] == 0 and mov[1] == 0) {
                //cout << "MOVE NOT IN MOVESET" << endl;
                return false;
            }
            
            if (newpos[0] > 7 or newpos[0] < 0) {
                //cout << "OUT OF BOUNDS" << endl;
                return false;
            }
            
            if (newpos[1] > 7 or newpos[1] < 0) {
                //cout << "OUT OF BOUNDS" << endl;
                return false;
            }
            



            Piece capture = plist[find(newpos)];
            
            
            if (piece.color == capture.color) { // if pieces are the same color.
                //cout << "CANNOT CAPTURE YOUR OWN PIECE" << endl;
                return false;
            }
            
            if (plist[find(newpos)].type == KING) {
                //cout << "CANNOT CAPTURE KING" << endl;
                return false;
            }

            
            // runback function
            
            if (piece.type == ROOK or piece.type == BISHOP or piece.type == QUEEN) {
                
                int fullstop;
                
                if (mov[0] != 0) {
                    fullstop = mov[0];
                } else {
                    fullstop = mov[1];
                }

                
                for (int i = 1; i < abs(fullstop); i++) {
                    
                    vector<int> temp = {0,0};
                    
                    if (mov[0] < 0) {
                        temp[0] = mov[0] + i;
                    } else if (mov[0] > 0) {
                        temp[0] = mov[0] - i;
                    }
                    
                    if (mov[1] < 0) {
                        temp[1] = mov[1] + i;
                    } else if (mov[1] > 0) {
                        temp[1] = mov[1] - i;
                    }

                    /*
                    cout << temp[0] << "," << temp[1] << endl;
                    cout << piece.pos[0] + temp[0] << "," << piece.pos[1] + temp[1] << endl;
                    cin.ignore();
                    cin.get();
                    */


                    if (plist[find({ piece.pos[0] + temp[0] , piece.pos[1] + temp[1] })].color != NOCOL) {
                        return false;
                    }
                    
                }
            }
            
            curcap = capture;

            return true;
        }
        
        
        void movepiece(Piece piece, vector<int> newpos, bool actual) {
            
            if (actual) {
                plist[find(piece.pos)].timesmoved += 1;
            }
            
            plist[find(newpos)].status = false;
            plist[find(newpos)].pos = { -99,-99 };

            plist[find(piece.pos)].pos = newpos;
        }
        
        
        void capture() {
            plist[find(curcap.pos)].status = false;
            plist[find(curcap.pos)].pos = {-99,-99};
        }
        
        void printboard()  {
            
            for (int k = 0; k < 8; k++) {
                cout << (char)(97 + k) << " ";
            }
            
            cout << endl << "- - - - - - - -"<< endl;
            
            for (int i = 0; i < 8; i++) {
                for (int j = 0; j < 8; j++) {
                    if (plist[find({j,i})].color == NOCOL) {
                        
                        switch ((i + j) % 2) {
                            case 0:
                                cout << "  ";
                                break;
                            case 1:
                                cout << "# ";
                                break;
                        }
                        
                    } else if (plist[find({j,i})].color == PWHITE) {

                        switch(plist[find({j,i})].type) {
                            case PAWN:
                                cout << "P ";
                                break;
                            case ROOK:
                                cout << "R ";
                                break;
                            case BISHOP:
                                cout << "B ";
                                break;
                            case KNIGHT:
                                cout << "N ";
                                break;
                            case QUEEN:
                                cout << "Q ";
                                break;
                            case KING:
                                cout << "K ";
                                break;
                        }
                    } else {
                        switch(plist[find({j,i})].type) {
                            case PAWN:
                                cout << "p ";
                                break;
                            case ROOK:
                                cout << "r ";
                                break;
                            case BISHOP:
                                cout << "b ";
                                break;
                            case KNIGHT:
                                cout << "n ";
                                break;
                            case QUEEN:
                                cout << "q ";
                                break;
                            case KING:
                                cout << "k ";
                                break;
                        }
                    }
                    
                    
                }
                
                cout << "| " << i + 1 <<endl;
            }
        }

        bool sidechecked(int side) {

            int kindex = 0;

            for (int i = 0; i < 33; i++) {

                if (plist[i].color == side and plist[i].type == KING) {
                    kindex = i;
                    break;
                }

            }


            for (int i = 1; i < 33; i++) {

                if (plist[i].color == side) {
                    continue;
                }

                if (plist[i].type == PAWN) {
                    for (int j = 1; j < plist[i].specoffsets.size() - 1; j++) {
                        //cout << plist[i].pos[0] + plist[i].specoffsets[j][0] << " " << plist[i].pos[1] + plist[i].specoffsets[j][1] << endl;


                        if (plist[i].pos[0] + plist[i].specoffsets[j][0] == plist[kindex].pos[0] and plist[i].pos[1] + plist[i].specoffsets[j][1] == plist[kindex].pos[1]) {

                            return true;
                        }

                    }
                }
                else {
                    for (int j = 0; j < plist[i].offsets.size(); j++) {



                        if (plist[i].pos[0] + plist[i].offsets[j][0] == plist[kindex].pos[0] and plist[i].pos[1] + plist[i].offsets[j][1] == plist[kindex].pos[1]) {

                            if (plist[i].type == ROOK or plist[i].type == BISHOP or plist[i].type == QUEEN) {

                                int fullstop;

                                if (plist[i].offsets[j][0] != 0) {
                                    fullstop = plist[i].offsets[j][0];
                                }
                                else {
                                    fullstop = plist[i].offsets[j][1];
                                }

                                for (int k = 1; k < abs(fullstop); k++) {

                                    vector<int> temp = { 0,0 };

                                    if (plist[i].offsets[j][0] < 0) {
                                        temp[0] = plist[i].offsets[j][0] + k;
                                    }
                                    else if (plist[i].offsets[j][0] > 0) {
                                        temp[0] = plist[i].offsets[j][0] - k;
                                    }

                                    if (plist[i].offsets[j][1] < 0) {
                                        temp[1] = plist[i].offsets[j][1] + k;
                                    }
                                    else if (plist[i].offsets[j][1] > 0) {
                                        temp[1] = plist[i].offsets[j][1] - k;
                                    }

                                    if (plist[find({ plist[i].pos[0] + temp[0] , plist[i].pos[1] + temp[1] })].type != NOTYPE) {
                                        return false;
                                    }
                                }

                            }

                            return true;
                        }
                    }

                }


          
            }

            return false;

        }


        bool sidecheckmate(int side) {

            int kindex = 0;
            bool checkmate = true;

            for (int i = 0; i < 33; i++) {

                if (plist[i].color == side and plist[i].type == KING) {
                    kindex = i;
                    break;
                }

            }

            for (int i = 1; i < 33; i++) {

                if (plist[i].color != side) {
                    continue;
                }

                vector<int> curpos = plist[i].pos;

                if (plist[i].type == PAWN) {
                    for (int j = 0; j < 3; j++) {

                        vector<int> newpos = { curpos[0] + plist[i].specoffsets[j][0], curpos[1] + plist[i].specoffsets[j][1] };

                        bool newstatus = plist[find(newpos)].status;
                        vector<int> capturedpos = plist[find(newpos)].pos;
                        int capturedtype = plist[find(newpos)].type;
                        int capturedcolor = plist[find(newpos)].color;
                        
                        int newindex = find(newpos);

                        if (checkmove(plist[i], newpos, side)) {
                            movepiece(plist[i], newpos, false);

                            if (!sidechecked(side)) {
                                checkmate = false;
                            }

                            movepiece(plist[i], curpos, false);
                            plist[newindex].status = newstatus;
                            plist[newindex].pos = capturedpos;


                        }

                    }
                }
                else {
                    for (int j = 0; j < plist[i].offsets.size(); j++) {

                        vector<int> newpos = { curpos[0] + plist[i].offsets[j][0], curpos[1] + plist[i].offsets[j][1] };
                        bool newstatus = plist[find(newpos)].status;
                        vector<int> capturedpos = plist[find(newpos)].pos;
                        int capturedtype = plist[find(newpos)].type;
                        int capturedcolor = plist[find(newpos)].color;
                        
                        int newindex = find(newpos);

                        if (checkmove(plist[i], newpos, side)) {
                            movepiece(plist[i], newpos, false);

                            if (!sidechecked(side)) {
                                checkmate = false;
                            }

                            movepiece(plist[i], curpos, false);
                            plist[newindex].status = newstatus;
                            plist[newindex].pos = capturedpos;
                        }


                    }
                }
            }

            return checkmate;


        }
        
        void castlecheck() {
            
            if (plist[find({5,7})].type == KING and plist[find({6,7})].type == ROOK
            and plist[find({5,7})].color == PWHITE and plist[find({6,7})].color == PWHITE
            and plist[find({5,7})].timesmoved == 1 and plist[find({6,7})].timesmoved == 1) {
                int i1 = find({5,7});
                int i2 = find({6,7});
                
                plist[i1].pos = {6,7};
                plist[i2].pos = {5,7};
                
            }
            
            if (plist[find({2,7})].type == KING and plist[find({1,7})].type == ROOK
            and plist[find({2,7})].color == PWHITE and plist[find({1,7})].color == PWHITE
            and plist[find({2,7})].timesmoved == 1 and plist[find({1,7})].timesmoved == 1) {
                int i1 = find({2,7});
                int i2 = find({1,7});
                
                plist[i1].pos = {1,7};
                plist[i2].pos = {2,7};
                
            }
            
            if (plist[find({5,0})].type == KING and plist[find({6,0})].type == ROOK
            and plist[find({5,0})].color == PBLACK and plist[find({6,0})].color == PBLACK
            and plist[find({5,0})].timesmoved == 1 and plist[find({6,0})].timesmoved == 1) {
                int i1 = find({5,0});
                int i2 = find({6,0});
                
                plist[i1].pos = {6,0};
                plist[i2].pos = {5,0};
                
            }
            
            if (plist[find({2,0})].type == KING and plist[find({1,0})].type == ROOK
            and plist[find({2,0})].color == PBLACK and plist[find({1,0})].color == PBLACK
            and plist[find({2,0})].timesmoved == 1 and plist[find({1,0})].timesmoved == 1) {
                int i1 = find({2,0});
                int i2 = find({1,0});
                
                plist[i1].pos = {1,0};
                plist[i2].pos = {2,0};
                
            }
            
        }
        
        
        bool preventcheck(int side, vector<int> newpos, vector<int> curpos) {
            
            bool ret = false;
            
            bool newstatus = plist[find(newpos)].status;
            vector<int> capturedpos = plist[find(newpos)].pos;
            
            int newindex = find(newpos);
            int curindex = find(curpos);
            movepiece(plist[curindex], newpos,false);

            if (!sidechecked(side)) {
                ret = true;
            }
            
            movepiece(plist[curindex], curpos,false);
            plist[newindex].status = newstatus;
            plist[newindex].pos = capturedpos;
            
            return ret;
        }
    
        vector<int> promotioncheck() {
            vector<int> ret = {0,0};
            
            for (int i = 0; i < 7; i++) {
                if (plist[find({i,7})].type == PAWN and plist[find({i,7})].color == PBLACK) {
                    ret[0] = 1;
                    ret[1] = find({i,7});
                }
            }
            
            for (int i = 0; i < 7; i++) {
                if (plist[find({i,0})].type == PAWN and plist[find({i,7})].color == PWHITE) {
                    ret[0] = 1;
                    ret[1] = find({i,0});
                }
            }
            
            return ret;
        }
        
};
