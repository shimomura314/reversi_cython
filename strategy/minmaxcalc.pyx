# distutils: language=c++
# cython: language_level=3, boundscheck=False, wraparound=False
# cython: cdivision=True

"""cythonize -3 -a -i .\strategy\minmaxcalc.pyx"""

import cython
from cython.view cimport array
import os
import sys

parent_dir = os.path.abspath(os.path.join(os.getcwd(), ".."))
sys.path.append(parent_dir)

from bitboard.bitothello cimport OthelloGameC


cdef extern from "<cstdint>" namespace "std":
    ctypedef unsigned long long uint64_t


cdef extern from "math.h":
    float INFINITY


cdef public class MinmaxC [object MinmaxCObject, type MinmaxCType]:

    cdef int _EVAL_TBL1[64]
    cdef int _EVAL_TBL2[64]
    cdef uint64_t _EXP2[64]
    cdef int _player_clr
    cdef int _count_pass
    cdef OthelloGameC _othello
    cdef int depth

    # Declaration of methods (bit othello).
    cpdef int _bit_count(self, uint64_t x)
    cpdef uint64_t _check_surround(self, uint64_t put_loc, int direction)
    cpdef (uint64_t, uint64_t) simulate_play(
        self, int turn, uint64_t put_loc,
        uint64_t black_board, uint64_t white_board,
        )
    cpdef (int, int) count_disks(
        self, uint64_t black_board, uint64_t white_board)
    cpdef uint64_t reversible_area(
        self, unsigned char turn, uint64_t black_board, uint64_t white_board)
    cpdef bint is_reversible(
        self, unsigned char turn, uint64_t put_loc,
        uint64_t black_board, uint64_t white_board,
        )
    cpdef bint turn_playable(
        self, unsigned char turn, uint64_t black_board, uint64_t white_board)

    # Declaration of methods.
    cdef int touch_border(self, uint64_t black_board, uint64_t white_board)
    cdef float evaluate_value(self, uint64_t black_board, uint64_t white_board)
    cdef (float, int) min_max(
        self, uint64_t black_board, uint64_t white_board, int turn,
        int depth, float pre_evaluation
        )
    cpdef int put_disk(self, OthelloGameC othello)

    def __cinit__(self, int depth=4):
        """Initializes an instance of the class.

        Parameters
        ----------
        depth : int, optional
            The maximum depth to which the minimax algorithm will search for the best move.
            Default value is 4.

        Notes
        -----
        This method initializes the instance with evaluation tables and an array of powers of 2 used for fast bit manipulation.
        The evaluation tables are precomputed values used to evaluate the board state in the minimax algorithm.
        The array of powers of 2 is used to quickly calculate the binary representation of a given integer.
        ``_EVAL_TBL1`` and ``_EVAL_TBL2`` are tables used to evaluate the board state for different positions.
        ``_EXP2`` is an array of powers of 2 that are used for bit manipulation operations.
        """
        self._EVAL_TBL1[0:64] = [
            30,  -12,   0,  -1,  -1,   0, -12,  30,
            -12, -15,  -3,  -3,  -3,  -3, -15, -12,
            0,    -3,   0,  -1,  -1,   0,  -3,   0,
            -1,   -3,  -1,  -1,  -1,  -1,  -3,  -1,
            -1,   -3,  -1,  -1,  -1,  -1,  -3,  -1,
            0,    -3,   0,  -1,  -1,   0,  -3,   0,
            -12, -15,  -3,  -3,  -3,  -3, -15, -12,
            30,  -12,   0,  -1,  -1,   0, -12,  30,
        ]
        self._EVAL_TBL2[0:64] = [
            120, -20,  20,   5,   5,  20, -20, 120,
            -20, -40,  -5,  -5,  -5,  -5, -40, -20,
            20,   -5,  15,   3,   3,  15,  -5,  20,
            5,    -5,   3,   3,   3,   3,  -5,   5,
            5,    -5,   3,   3,   3,   3,  -5,   5,
            20,   -5,  15,   3,   3,  15,  -5,  20,
            -20, -40,  -5,  -5,  -5,  -5, -40, -20,
            120, -20,  20,   5,   5,  20, -20, 120,
        ]
        self._EXP2[0:64] = [
            1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192,
            16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152,
            4194304, 8388608, 16777216, 33554432, 67108864, 134217728,
            268435456, 536870912, 1073741824, 2147483648, 4294967296,
            8589934592, 17179869184, 34359738368, 68719476736, 137438953472,
            274877906944, 549755813888, 1099511627776, 2199023255552,
            4398046511104, 8796093022208, 17592186044416, 35184372088832,
            70368744177664, 140737488355328, 281474976710656, 562949953421312,
            1125899906842624, 2251799813685248, 4503599627370496,
            9007199254740992, 18014398509481984, 36028797018963968,
            72057594037927936, 144115188075855872, 288230376151711744,
            576460752303423488, 1152921504606846976, 2305843009213693952,
            4611686018427387904, 9223372036854775808,
        ]
        self.depth = depth

    # Difinitions of methods.
    cpdef int _bit_count(self, uint64_t x):
        # Distributing by 2-bit, express the number of bits using 2-bit.
        x -= (x >> 1) & 0x5555555555555555ULL
        # Upper 2-bit + lower 2-bit.
        x = (x & 0x3333333333333333ULL) + ((x >> 2) & 0x3333333333333333ULL)
        # Upper 4-bit + lower 4-bit.
        x = (x + (x >> 4)) & 0x0f0f0f0f0f0f0f0fULL
        # Upper 8-bit + lower 8-bit.
        x += x >> 8
        # Upper 16-bit + lower 16-bit.
        x += x >> 16
        # Upper 32-bit + lower 32-bit.
        x += x >> 32
        return x & 0x0000007fULL

    cpdef uint64_t _check_surround(self, uint64_t put_loc, int direction):
        if direction == 0:  # Upper
            return (put_loc << 8) & 0xffffffffffffff00ULL
        elif direction == 1:  # Upper right
            return (put_loc << 7) & 0x7f7f7f7f7f7f7f00ULL
        elif direction == 2:  # Right
            return (put_loc >> 1) & 0x7f7f7f7f7f7f7f7fULL
        elif direction == 3:  # Lower right
            return (put_loc >> 9) & 0x007f7f7f7f7f7f7fULL
        elif direction == 4:  # Lower
            return (put_loc >> 8) & 0x00ffffffffffffffULL
        elif direction == 5:  # Lower left
            return (put_loc >> 7) & 0x00fefefefefefefeULL
        elif direction == 6:  # Left
            return (put_loc << 1) & 0xfefefefefefefefeULL
        elif direction == 7:  # Upper left
            return (put_loc << 9) & 0xfefefefefefefe00ULL

    cpdef (uint64_t, uint64_t) simulate_play(
            self, int turn, uint64_t put_loc,
            uint64_t black_board, uint64_t white_board,
            ):
        cdef uint64_t reverse_bit = 0
        cdef uint64_t reverse_bit_
        cdef uint64_t border_bit
        if turn == 0:
            # Player is black_board.
            for direction in range(8):
                reverse_bit_ = 0
                border_bit = <uint64_t> self._check_surround(put_loc, direction)
                while border_bit & white_board:
                    reverse_bit_ |= border_bit
                    border_bit = self._check_surround(border_bit, direction)
                # If player's disk is opposite side.
                if border_bit & black_board:
                    reverse_bit |= reverse_bit_
            black_board ^= (put_loc | reverse_bit)
            white_board ^= reverse_bit
        else:
            # Player is white_board.
            for direction in range(8):
                reverse_bit_ = 0
                border_bit = <uint64_t> self._check_surround(put_loc, direction)
                while border_bit & black_board:
                    reverse_bit_ |= border_bit
                    border_bit = self._check_surround(border_bit, direction)
                # If player's disk is opposite side.
                if border_bit & white_board:
                    reverse_bit |= reverse_bit_
            white_board ^= (put_loc | reverse_bit)
            black_board ^= reverse_bit

        return black_board, white_board

    cpdef (int, int) count_disks(
            self, uint64_t black_board, uint64_t white_board):
        return self._bit_count(black_board), self._bit_count(white_board)

    cpdef uint64_t reversible_area(
            self, unsigned char turn, uint64_t black_board, uint64_t white_board):
        cdef uint64_t *CONST = [
            0x7e7e7e7e7e7e7e7eULL, 0x00ffffffffffff00ULL, 0x007e7e7e7e7e7e00ULL,
        ]
        cdef uint64_t *board = [black_board, white_board]
        cdef uint64_t blank_board = ~(board[0] | board[1])

        cdef uint64_t horiz_brd = board[turn ^ 1] & CONST[0]
        cdef uint64_t vert_brd = board[turn ^ 1] & CONST[1]
        cdef uint64_t all_border = board[turn ^ 1] & CONST[2]

        # Upper
        cdef uint64_t one_rv = horiz_brd & (board[turn] << 1)
        one_rv |= horiz_brd & (one_rv << 1)
        one_rv |= horiz_brd & (one_rv << 1)
        one_rv |= horiz_brd & (one_rv << 1)
        one_rv |= horiz_brd & (one_rv << 1)
        one_rv |= horiz_brd & (one_rv << 1)
        cdef uint64_t reversible = blank_board & (one_rv << 1)

        # Lower
        one_rv = horiz_brd & (board[turn] >> 1)
        one_rv |= horiz_brd & (one_rv >> 1)
        one_rv |= horiz_brd & (one_rv >> 1)
        one_rv |= horiz_brd & (one_rv >> 1)
        one_rv |= horiz_brd & (one_rv >> 1)
        one_rv |= horiz_brd & (one_rv >> 1)
        reversible |= blank_board & (one_rv >> 1)

        # Left
        one_rv = vert_brd & (board[turn] << 8)
        one_rv |= vert_brd & (one_rv << 8)
        one_rv |= vert_brd & (one_rv << 8)
        one_rv |= vert_brd & (one_rv << 8)
        one_rv |= vert_brd & (one_rv << 8)
        one_rv |= vert_brd & (one_rv << 8)
        reversible |= blank_board & (one_rv << 8)

        # Right
        one_rv = vert_brd & (board[turn] >> 8)
        one_rv |= vert_brd & (one_rv >> 8)
        one_rv |= vert_brd & (one_rv >> 8)
        one_rv |= vert_brd & (one_rv >> 8)
        one_rv |= vert_brd & (one_rv >> 8)
        one_rv |= vert_brd & (one_rv >> 8)
        reversible |= blank_board & (one_rv >> 8)

        # Upper right
        one_rv = all_border & (board[turn] << 7)
        one_rv |= all_border & (one_rv << 7)
        one_rv |= all_border & (one_rv << 7)
        one_rv |= all_border & (one_rv << 7)
        one_rv |= all_border & (one_rv << 7)
        one_rv |= all_border & (one_rv << 7)
        reversible |= blank_board & (one_rv << 7)

        # Upper left
        one_rv = all_border & (board[turn] << 9)
        one_rv |= all_border & (one_rv << 9)
        one_rv |= all_border & (one_rv << 9)
        one_rv |= all_border & (one_rv << 9)
        one_rv |= all_border & (one_rv << 9)
        one_rv |= all_border & (one_rv << 9)
        reversible |= blank_board & (one_rv << 9)

        # Lower right
        one_rv = all_border & (board[turn] >> 9)
        one_rv |= all_border & (one_rv >> 9)
        one_rv |= all_border & (one_rv >> 9)
        one_rv |= all_border & (one_rv >> 9)
        one_rv |= all_border & (one_rv >> 9)
        one_rv |= all_border & (one_rv >> 9)
        reversible |= blank_board & (one_rv >> 9)

        # Lower left
        one_rv = all_border & (board[turn] >> 7)
        one_rv |= all_border & (one_rv >> 7)
        one_rv |= all_border & (one_rv >> 7)
        one_rv |= all_border & (one_rv >> 7)
        one_rv |= all_border & (one_rv >> 7)
        one_rv |= all_border & (one_rv >> 7)
        reversible |= blank_board & (one_rv >> 7)
        return reversible

    cpdef bint is_reversible(
            self, unsigned char turn, uint64_t put_loc,
            uint64_t black_board, uint64_t white_board,
            ):
        reversible = self.reversible_area(turn, black_board, white_board)
        return (put_loc & reversible) == put_loc

    cpdef bint turn_playable(
            self, unsigned char turn, uint64_t black_board, uint64_t white_board):
        reversible = self.reversible_area(turn, black_board, white_board)
        return reversible != 0

    cdef int touch_border(self, uint64_t black_board, uint64_t white_board):
        """
        Check if any stone on the board is touching the border.

        Parameters:
        -----------
        black_board : uint64_t
            Bitboard representing the current state of black stones on the board.
        white_board : uint64_t
            Bitboard representing the current state of white stones on the board.

        Returns:
        --------
        int
            Returns 1 if a stone is touching the border, otherwise returns 0.
        """
        cdef uint64_t board = (black_board | white_board)
        if board & 0xff818181818181ffULL:
            return 1
        return 0

    cdef float evaluate_value(self, uint64_t black_board, uint64_t white_board):
        """
        Evaluate the value of the current board position.

        Parameters
        ----------
        black_board : uint64_t
            A 64-bit unsigned integer representing the position of black discs on the board.
        white_board : uint64_t
            A 64-bit unsigned integer representing the position of white discs on the board.

        Returns
        -------
        float
            A floating point number representing the evaluation value of the current board position.

        Notes
        -----
        This method calculates the evaluation value of the current board position by iterating over the positions of
        black and white discs on the board, and adding or subtracting the corresponding values from the evaluation
        tables based on the disc positions and the current game phase. The game phase is determined by checking if any
        of the discs touch the border of the board.

        The evaluation tables used in this method are pre-calculated values that are based on the strategic
        importance of each board position. The values in EVAL_TBL1 are used in the opening and early midgame phases,
        while the values in EVAL_TBL2 are used in the late midgame and endgame phases.
        """
        cdef float evaluation = 0
        cdef uint64_t *board = [black_board, white_board]

        # If disk does not touch the border,
        # phase is False and TABLE[0] is called.
        phase = self.touch_border(black_board, white_board)
        for position in range(64):
            if phase == 0:
                # If a disc is on an edge square.
                if (self._EXP2[position] & board[self._player_clr]):
                    evaluation += self._EVAL_TBL1[position]
                if (self._EXP2[position] & board[self._player_clr ^ 1]):
                    evaluation -= self._EVAL_TBL1[position]
            else:
                if (self._EXP2[position] & board[self._player_clr]):
                    evaluation += self._EVAL_TBL2[position]
                if (self._EXP2[position] & board[self._player_clr ^ 1]):
                    evaluation -= self._EVAL_TBL2[position]
        return evaluation

    cdef (float, int) min_max(
            self, uint64_t black_board, uint64_t white_board, int turn,
            int depth, float pre_evaluation
            ):
        """
        Min-Max Algorithm with Alpha-Beta Pruning.

        Parameters
        ----------
        black_board : uint64_t
            Bitboard representation of the black player's disks.
        white_board : uint64_t
            Bitboard representation of the white player's disks.
        turn : int
            If black is on turn, 1. If white, 0.
        depth : int
            Search depth.
        pre_evaluation : float
            Previous evaluation value for alpha-beta pruning.

        Returns
        -------
        evaluation : float
            Evaluation value.
        selected : int
            The position of the disk to be placed.
        """
        # Calculate evaluation.
        cdef float evaluation = self.evaluate_value(black_board, white_board)
        cdef float max_evaluation
        cdef float min_evaluation
        cdef float next_evaluation 
        cdef uint64_t new_black_board
        cdef uint64_t new_white_board
        cdef int count_black
        cdef int count_white
        cdef int selected

        if depth == 0:
            return evaluation, 1

        if turn == self._player_clr:
            max_evaluation = -1 * INFINITY
        else:
            min_evaluation = INFINITY

        cdef uint64_t reversible = self.reversible_area(
            turn, black_board, white_board
            )

        if self.turn_playable(turn, black_board, white_board):
            # Skip unplayable area.
            for i in range(64):
                if not (self._EXP2[i] & reversible):
                    continue

                new_black_board, new_white_board = \
                    self.simulate_play(
                        turn, self._EXP2[i],
                        black_board, white_board,
                    )
                count_black, count_white = self.count_disks(
                    new_black_board, new_white_board
                )
                if self._player_clr:
                    count_player, count_opponent = count_black, count_white
                else:
                    count_player, count_opponent = count_white, count_black
                if self._othello.judge_game(count_player, count_opponent):
                    if self._othello.result == "WIN":
                        next_evaluation = 10000000000
                    elif self._othello.result == "LOSE":
                        next_evaluation = -10000000000
                    else:
                        next_evaluation = 0
                else:
                    if turn == self._player_clr:
                        next_evaluation = self.min_max(
                            new_black_board, new_white_board,
                            turn ^ 1, depth-1, max_evaluation,
                            )[0]
                    else:
                        next_evaluation = self.min_max(
                            new_black_board, new_white_board,
                            turn ^ 1, depth-1, min_evaluation,
                            )[0]

                # alpha-bata method(pruning)
                if turn == self._player_clr:
                    if next_evaluation > pre_evaluation:
                        return next_evaluation, i
                else:
                    if pre_evaluation > next_evaluation:
                        return next_evaluation, i

                if turn == self._player_clr:
                    if max_evaluation < next_evaluation:
                        max_evaluation = next_evaluation
                        selected = i
                else:
                    if next_evaluation < min_evaluation:
                        min_evaluation = next_evaluation
                        selected = i
        else:
            if turn == self._player_clr:
                return self.min_max(
                    black_board, white_board, turn^1, depth-1, max_evaluation,
                    )
            else:
                return self.min_max(
                    black_board, white_board, turn^1, depth-1, min_evaluation,
                    )
        if turn == self._player_clr:
            return max_evaluation, selected
        else:
            return min_evaluation, selected

    cpdef int put_disk(self, OthelloGameC othello):
        """Put a disk in a reversible position.

        Parameters
        ----------
        othello : OthelloGameC
            Othello game object.

        Returns
        -------
        int
            Position of the disk placed.
        """
        cdef uint64_t new_black_board
        cdef uint64_t new_white_board

        black_board, white_board = othello.return_board()
        cdef int turn = othello.turn
        self._player_clr = turn
        self._count_pass = 0
        self._othello = othello
        return self.min_max(
            black_board, white_board, turn, self.depth, INFINITY)[1]
