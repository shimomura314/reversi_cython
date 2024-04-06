# distutils: language=c++
# cython: language_level=3, boundscheck=False, wraparound=False
# cython: cdivision=True

"""cythonize -3 -a -i .\bitboard\bitothello.pyx"""

import copy
from collections import deque
from logging import getLogger
import random

logger = getLogger(__name__)


cdef public class OthelloGameC [object OthelloGameCObject, type OthelloGameCType]:

    def __cinit__(self):
        self.BLACK = 0
        self.WHITE = 1
        self.INIT_BLACK = 0x0000000810000000ULL
        self.INIT_WHITE = 0x0000001008000000ULL
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

    def __init__(self, str player_clr="black"):
        """
        Othello board game.

        Parameters
        ----------
        player_clr : str, optional
            The color of the player, either "black", "white", or "random".
            Default is "black".

        Attributes
        ----------
        _black_board : int
            A bitboard representing the black pieces.
        _white_board : int
            A bitboard representing the white pieces.
        _player_clr : int
            The color of the player as an integer, where 0 represents black and 1 represents white.
        turn : int
            The current turn number.
        reversible : int
            The number of reversible positions.
        result : str
            The current result of the game.
        _count_player : int
            The number of player's pieces on the board.
        _count_opponent : int
            The number of opponent's pieces on the board.
        _pass_cnt : list of int
            The number of times each player has passed.
        _player_auto : bool
            Whether the player is controlled by a computer or not.
        _board_log : deque
            A deque containing the history of the board.
        _board_back : deque
            A deque containing the backup of the board.

        Raises
        ------
        KeyError
            If an invalid color string is specified.

        Notes
        -----
        This class represents an Othello board game.
        The board is represented as a bitboard, where each bit represents a position on the board.
        The bit at index i represents the position (i % 8, i // 8) on the board.

        Examples
        --------
        >>> game = OthelloBoard(player_clr="white")
        >>> game.play()
        """
        # Set a board.
        self._black_board = 0x0000000810000000ULL
        self._white_board = 0x0000001008000000ULL

        # Black or white.
        if player_clr == "black":
            self._player_clr = self.BLACK
        elif player_clr == "white":
            self._player_clr = self.WHITE
        elif player_clr == "random":
            self._player_clr = random.choice([0, 1])
        else:
            raise KeyError

        # States of game.
        self.turn = 0
        self.reversible = 0
        self.result = "start"

        # Counter.
        self._count_player = 2
        self._count_opponent = 2
        self._pass_cnt = [0, 0]  # [white, black]

        # Mode.
        self._player_auto = False
        logger.info("Game starts.")

        # Logger.
        self._board_log = deque([])
        self._board_back = deque([])

    # Difinitions of methods.
    cpdef int _bit_count(self, uint64_t x):
        """
        Count the number of bit awaking.

        Parameters
        ----------
        x : uint64_t
            An unsigned 64-bit integer which represents the location of disk.

        Returns
        -------
        uint64_t
            The number of bits in the integer.

        Notes
        -----
        This method uses the "population count" algorithm to count
        the number of bits in an integer.
        It works by first distributing the bits by 2-bit,
        then adding the upper and lower bits at each level
        until the entire 64-bit integer is summed up.

        Examples
        --------
        >>> game = OthelloBoard()
        >>> game._bit_count(0x0000000810000000ULL)
        3
        """
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
        """
        Check neighbor disk is reversible or not.

        Parameters
        ----------
        put_loc : uint64_t
            The location where the player puts their disk represented
            as a 64-bit unsigned integer.
        direction : int
            An integer representing the direction to check.
            It should be an integer in the range [0, 7].
            0: upper, 1: upper right, 2: right, 3: lower right,
            4: lower,5: lower left, 6: left, 7: upper left.
        """
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
            uint64_t black_board = 0, uint64_t white_board = 0,
            ):
        """
        Simulates a play of Othello by updating the current board state.

        Parameters
        ----------
        turn : int
            The player who is making the play. 0 for black, 1 for white.
        put_loc : uint64_t
            The location where the player puts their disk represented
            as a 64-bit unsigned integer.
        black_board, white_board : uint64_t, optional
            Bitboard representing player's discs.
            Default is 0, which means use the internal state of the board.

        Returns
        -------
        tuple of uint64_t
            A tuple of updated black and white bitboards after the player's move.
        """
        if black_board  == 0 and white_board == 0:
            black_board = self._black_board
            white_board = self._white_board

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

    cpdef void update_board(self, uint64_t black_board, uint64_t white_board):
        """
        Updates the game board with the provided black and white board configurations.

        Parameters
        ----------
        black_board, white_board : int
            The bitboard configuration of the black/white player.

        Returns
        -------
        None
        """
        self._black_board = black_board
        self._white_board = white_board

    cpdef (int, int) count_disks(
            self, uint64_t black_board = 0, uint64_t white_board = 0):
        """
        Counts the number of disks on the board for each player.

        Parameters
        ----------
        black_board, white_board : uint64_t, optional
            The bitboard representing the black/white player's disks.
            If not given, the internal board of the instance is used.

        Returns
        -------
        Tuple[int, int]
            A tuple with the number of disks for the players, respectively.
        """
        if black_board  == 0 and white_board == 0:
            black_board = self._black_board
            white_board = self._white_board

        return self._bit_count(black_board), self._bit_count(white_board)

    cpdef uint64_t reversible_area(
            self, unsigned char turn, uint64_t black_board = 0, uint64_t white_board = 0):
        """
        Calculate the reversible area of the board for the given turn.

        Parameters
        ----------
        turn : unsigned char
            The turn to calculate the reversible area for.
        black_board, white_board : uint64_t
            The boards represented as a 64-bit integer.
            Defaults to 0.

        Returns
        -------
        reversible : uint64_t
            The reversible area of the board for the given turn.
        """
        if black_board  == 0 and white_board == 0:
            black_board = self._black_board
            white_board = self._white_board

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

    cpdef list reversible_area_list(
            self, unsigned char turn, uint64_t black_board = 0, uint64_t white_board = 0):
        cdef uint64_t reversible = self.reversible_area(turn, black_board, white_board)

        cdef int num
        cdef list candidates = []
        for num in range(64):
            if (reversible & self._EXP2[num]):
                candidates.append(num)
        return candidates

    cpdef bint is_reversible(
            self, unsigned char turn, uint64_t put_loc,
            uint64_t black_board = 0, uint64_t white_board = 0,
            ):
        """
        Check if the put_loc is reversible for the given turn.

        Parameters
        ----------
        turn : unsigned char
            Current player's turn. `0` for black, `1` for white.
        put_loc : uint64_t
            The bitboard position to check reversibility.
        black_board, white_board : uint64_t, optional
            Bitboard representing the player's pieces on the board.
            Default is `0`.

        Returns
        -------
        bool
            `True` if the put_loc is reversible, `False` otherwise.
        """
        if black_board  == 0 and white_board == 0:
            black_board = self._black_board
            white_board = self._white_board

        reversible = self.reversible_area(turn, black_board, white_board)
        return (put_loc & reversible) == put_loc

    cpdef bint turn_playable(
            self, unsigned char turn, uint64_t black_board = 0, uint64_t white_board = 0):
        """Return wheather you can put disk or not.

        Parameters
        ----------
        turn : unsigned char
            The turn of the player to check. 0 for black, 1 for white.
        black_board, white_board : uint64_t, optional
            Bitboards representing the stones.
            Defaults to 0, in which case the current boards of the game will be used.
        
        Returns
        -------
        np.bool_
            True if the player has a valid move to make, False otherwise.
        """
        if black_board  == 0 and white_board == 0:
            black_board = self._black_board
            white_board = self._white_board

        reversible = self.reversible_area(turn, black_board, white_board)
        return reversible != 0

    cpdef (uint64_t, uint64_t) return_board(self):
        """
        Returns the current board of the game.

        Returns
        -------
        board : tuple of uint64_t
            A tuple of the black board and white board.
        """
        return self._black_board, self._white_board

    cpdef (uint64_t, uint64_t) return_player_board(self, int turn):
        """
        Returns the board of a player.

        Parameters
        ----------
        turn : int
            The player's turn. If 0, returns the black board and white board. If 1, returns the white board and black board.

        Returns
        -------
        board : tuple of uint64_t
            A tuple of the board of the player and the opponent's board.
        """
        if turn == 0:
            return self._black_board, self._white_board
        else:
            return self._white_board, self._black_board

    cpdef load_board(self, uint64_t black_board, uint64_t white_board):
        """
        Load the specified board.

        Parameters
        ----------
        black_board : uint64_t
            The black board.
        white_board : uint64_t
            The white board.
        """
        self._black_board = black_board
        self._white_board = white_board

    cpdef void play_turn(self, int put_loc):
        """
        Play a turn with the given location on the board.

        Parameters
        ----------
        put_loc : int
            Location to put the piece on the board, from 0 to 63.

        Raises
        ------
        AssertionError
            If the input value is not within 0 to 63.
        ValueError
            If the input value is not reversible.

        Returns
        -------
        None
        """
        if not (0 <= put_loc <= 63):
            raise AssertionError
        # cdef uint64_t put_loc_ = 1i64 << put_loc
        cdef uint64_t put_loc_ = self._EXP2[put_loc]
        cdef uint64_t next_black_board, next_white_board

        # If input value is not valid, raise an error.
        if not self.is_reversible(self.turn, put_loc_):
            raise ValueError

        next_black_board, next_white_board = self.simulate_play(
            self.turn, put_loc_, 0, 0)

        if self._player_clr == self.turn:
            # Delete roll back log which is no longer used.
            if self._board_back:
                self._board_back = deque([])
            self._board_log.append([next_black_board, next_white_board])

        # Update boards.
        self.update_board(next_black_board, next_white_board)
        self._pass_cnt[self.turn] = 0
        self.turn ^= 1

    cpdef (int, int) update_count(self):
        """
        Update the number of disks on the board for each player.

        Returns
        -------
            count_player : int
                The number of disks for the current player.
            count_opponent : int
                The number of disks for the opponent.
        """
        cdef int count_board[2]
        count_board[0], count_board[1] = self.count_disks()
        if self._player_clr == 0:
            self._count_player = count_board[0]
            self._count_opponent = count_board[1]
            return count_board[0], count_board[1]
        else:
            self._count_player = count_board[1]
            self._count_opponent = count_board[0]
            return count_board[1], count_board[0]

    cpdef bint judge_game(self, int player = 0, int opponent = 0):
        """
        Determines the outcome of the game based on the current state of the board.

        Parameters
        ----------
        player : int, optional
            The score of the current player, defaults to 0.
        opponent : int, optional
            The score of the opposing player, defaults to 0.

        Returns
        -------
        bool
            Returns True if the game is over, otherwise False.
        """
        if player == 0 and opponent == 0:
            player = self._count_player
            opponent = self._count_opponent

        # if self._pass_cnt >= 2 or sum(disk_count) == 64:
        cdef uint64_t black, white
        black = self.reversible_area(0)
        white = self.reversible_area(1)
        if (black == 0 and white == 0) or (player+opponent) == 64:
            if player == opponent:
                self.result = "DRAW"
            elif player > opponent:
                self.result = "WIN"
            elif player < opponent:
                self.result = "LOSE"
            return True
        return False

    cpdef void auto_mode(self, bint automode = True):
        """
        Set automatic mode.

        Parameters
        ----------
        automode : bool, optional
            Automatic mode on/off flag, by default True
        """
        self._player_auto = automode

    cpdef void load_strategy(self, object Strategy):
        """
        Load strategy for player and opponent.

        Parameters
        ----------
        Strategy : object
            Strategy object.
        """
        self._strategy_player = Strategy(self)
        self._strategy_opponent = Strategy(self)

    def change_strategy(self, str strategy, bint is_player=False, **kwargs):
        """
        Change strategy for player or opponent.

        Parameters
        ----------
        strategy : str
            Name of the strategy to be used.
        is_player : bool, optional
            Whether the player's strategy should be changed, by default False.
        """
        if is_player:
            self._strategy_player.set_strategy(strategy, **kwargs)
        else:
            self._strategy_opponent.set_strategy(strategy, **kwargs)

    cpdef (bint, bint) process_game(self):
        """
        Process the game by updating the count, judging whether the game is over,
        and making a move by the player or the CPU, depending on whose turn it is.

        Returns
        -------
        finished, updated : Tuple[bint, bint]
            A tuple representing if the game has ended
            and if a turn was played.
        """
        self.update_count()

        if self.judge_game():
            logger.debug("Game was judged as the end.")
            return True, True

        if self.turn == self._player_clr:
            self.reversible = self.reversible_area(self.turn)
            if self.turn_playable(self.turn):
                if self._player_auto:
                    logger.debug("Player's turn was processed automatically.")
                    self.play_turn(self._strategy_player.selecter(self))
                    return False, True
                else:
                    pass
            else:
                logger.debug("Player's turn was passed.")
                self.turn ^= 1
                self._pass_cnt[self.turn] += 1
        else:
            self.reversible = self.reversible_area(self.turn)
            if self.turn_playable(self.turn):
                logger.debug("CPU's turn was processed automatically.")
                self.play_turn(self._strategy_opponent.selecter(self))
                return False, True
            else:
                logger.debug("CPU's turn was passed.")
                self.turn ^= 1
                self._pass_cnt[self.turn] += 1
        return False, False

    cpdef list display_board(self):
        """
        Calculate 2-dimensional arrays to be used for board display.

        Returns
        -------
        list
            A list of lists with dimensions 8 x 8 where 1 represents a black disk,
            -1 represents a white disk, and 0 represents an empty cell.
        """
        cdef uint64_t black_board, white_board
        cdef int board_list[8][8]

        black_board, white_board = self.return_board()
        board_list = [[0 for _ in range(8)] for _ in range(8)]
        for row in range(8):
            for column in range(8):
                if black_board & 1:
                    board_list[row][column] = 1
                if white_board & 1:
                    board_list[row][column] = -1
                black_board = black_board >> 1
                white_board = white_board >> 1
        return board_list

    cpdef bint undo_turn(self):
        """
        Undo the last turn.

        Returns:
            bint: True if successful, False otherwise.
        """
        logger.debug(
            "Log:%s - %s" % (
                ", ".join(map(str, self._board_log)),
                ", ".join(map(str, self._board_back)),
                ))
        if not self._board_log:
            logger.warning("The board can not be playbacked.")
            return False

        logger.info("The board was playbacked.")
        previous_board = self._board_log.pop()
        self._board_back.append(self.return_board())
        self.load_board(*previous_board)

        logger.debug(
            "Log:%s - %s" % (
                ", ".join(map(str, self._board_log)),
                ", ".join(map(str, self._board_back)),
                ))
        return True

    cpdef bint redo_turn(self):
        """
        Redo the last undoed turn.

        Returns:
        - True if the board was advanced successfully.
        - False if there is no board to advance.
        """
        logger.debug(
            "Log:%s - %s" % (
                ", ".join(map(str, self._board_log)),
                ", ".join(map(str, self._board_back)),
                ))
        if not self._board_back:
            logger.warning("The board can not be advanced.")
            return False
        logger.info("The board was advanced.")
        next_board = self._board_back.pop()
        self._board_log.append(self.return_board())
        self.load_board(*next_board)
        logger.debug(
            "Log:%s - %s" % (
                ", ".join(map(str, self._board_log)),
                ", ".join(map(str, self._board_back)),
                ))
        return True

    cpdef int return_turn(self):
        """
        Returns the current turn of the game.

        Returns
        -------
        int
            An integer representing the current turn,
            where 0 represents the black and 1 represents the white.
        """
        return self._player_clr

    # cpdef (uint64_t, uint64_t, list, list) return_state(self):
    #     black_board, white_board = self.return_board()
    #     return black_board, white_board, self._board_log, self._board_back

    cpdef void load_state(
            self, uint64_t black_board, uint64_t white_board,
            list board_log, list board_back):
        """
        Load the current game state with the given board configuration and board history.

        Parameters
        ----------
        black_board : uint64_t
            The bitboard representing the black player's pieces.
        white_board : uint64_t
            The bitboard representing the white player's pieces.
        board_log : list
            The list of previous board states.
        board_back : list
            The list of next board states.

        Returns
        -------
        None
        """
        self.load_board(black_board, white_board)
        self._board_log = copy.deepcopy(board_log)
        self._board_back = copy.deepcopy(board_back)
