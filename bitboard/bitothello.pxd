cdef extern from "<cstdint>" namespace "std":
    ctypedef unsigned long long uint64_t


cdef public class OthelloGameC [object OthelloGameCObject, type OthelloGameCType]:

    # Class variables.
    cdef public int BLACK
    cdef public int WHITE
    cdef public uint64_t INIT_BLACK
    cdef public uint64_t INIT_WHITE
    cdef uint64_t _EXP2[64]

    # Instance variables.
    cdef public uint64_t _black_board
    cdef public uint64_t _white_board
    cdef int _player_clr
    cdef public int turn
    cdef public uint64_t reversible
    cdef public str result
    cdef int _count_player
    cdef int _count_opponent
    cdef int _pass_cnt[2]
    cdef bint _player_auto
    cdef public object _strategy_player
    cdef public object _strategy_opponent
    cdef object _board_log
    cdef object _board_back

    # Declaration of methods.
    cpdef int _bit_count(self, uint64_t x)
    cpdef uint64_t _check_surround(self, uint64_t put_loc, int direction)
    cpdef (uint64_t, uint64_t) simulate_play(
        self, int turn, uint64_t put_loc,
        uint64_t black_board=?, uint64_t white_board=?,
        )
    cpdef void update_board(self, uint64_t black_board, uint64_t white_board)
    cpdef (int, int) count_disks(
            self, uint64_t black_board=?, uint64_t white_board=?)
    cpdef uint64_t reversible_area(
        self, unsigned char turn, uint64_t black_board=?, uint64_t white_board=?)
    cpdef list reversible_area_list(
        self, unsigned char turn, uint64_t black_board=?, uint64_t white_board=?)
    cpdef bint is_reversible(
        self, unsigned char turn, uint64_t put_loc,
        uint64_t black_board=?, uint64_t white_board=?,
        )
    cpdef bint turn_playable(
        self, unsigned char turn, uint64_t black_board=?, uint64_t white_board=?)
    cpdef (uint64_t, uint64_t) return_board(self)
    cpdef (uint64_t, uint64_t) return_player_board(self, int turn)
    cpdef load_board(self, uint64_t black_board, uint64_t white_board)

    # Declaration of methods.
    cpdef void play_turn(self, int put_loc)
    cpdef (int, int) update_count(self)
    cpdef bint judge_game(self, int player=?, int opponent=?)
    cpdef void auto_mode(self, bint automode=?)
    cpdef void load_strategy(self, object Strategy)
    cpdef (bint, bint) process_game(self)
    cpdef list display_board(self)
    cpdef bint undo_turn(self)
    cpdef bint redo_turn(self)
    cpdef int return_turn(self)
    # cpdef (uint64_t, uint64_t, list, list) return_state(self)
    cpdef void load_state(
        self, uint64_t black_board, uint64_t white_board,
        list board_log, list board_back)
