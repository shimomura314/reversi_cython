"""This file defines menu bar."""

import copy
import wx

from bitboard import OthelloGame
from strategy import Strategy


class MenuBar(wx.MenuBar):
    """
    A class for setting up the menu bar in the Othello game GUI.

    Parameters
    ----------
    frame : wx.Frame
        The main frame of the GUI.

    Attributes:
    -----------
    _frame : wx.Frame
        The main frame of the GUI.
    _id_clr_black : int
        The ID of the "black" menu item in the "Procedure" menu.
    _id_clr_white : int
        The ID of the "white" menu item in the "Procedure" menu.
    _id_clr_random : int
        The ID of the "random" menu item in the "Procedure" menu.
    _id_random : int
        The ID of the "random" radio item in the "CPU strategy" menu.
    _id_maximize : int
        The ID of the "maximize" radio item in the "CPU strategy" menu.
    _id_minimize : int
        The ID of the "minimize" radio item in the "CPU strategy" menu.
    _id_minmax : int
        The ID of the "min-max" radio item in the "CPU strategy" menu.
    _board_save : list
        The saved state of the Othello board.
    _board_log : list
        The log of previous moves on the Othello board.
    _board_back : list
        The backup of the Othello board.

    Methods:
    --------
    save_board():
        Saves the current state of the Othello board.
    load_board():
        Loads the saved state of the Othello board.
    initialize_game():
        Initializes the Othello board.
    close_game():
        Closes the Othello game GUI.
    undo_turn():
        Undoes the last turn on the Othello board.
    redo_turn():
        Redoes the last turn on the Othello board.
    change_settings(event):
        Changes the settings of the Othello board and CPU strategy.
    event_manager(event):
        Manages events triggered by user actions in the menu bar.
    """

    def __init__(self, frame):
        """
        Initializes the MenuBar class.

        Parameters
        ----------
        frame : wx.Frame
            The main frame of the GUI.
        """
        super().__init__()
        self._frame = frame

        # Basic menu.
        menu_file = wx.Menu()
        menu_file.Append(wx.ID_SAVE, "Save")
        menu_file.Append(wx.ID_REPLACE, "Load")
        menu_file.Append(wx.ID_RESET, "Initialize")
        menu_file.AppendSeparator()
        menu_file.Append(wx.ID_EXIT, "Exit")

        # Operation menu.
        menu_edit = wx.Menu()
        menu_edit.Append(wx.ID_UNDO, "Undo")
        menu_edit.Append(wx.ID_REDO, "Redo")

        # Select color of player disk.
        menu_proc = wx.Menu()
        self._id_clr_black = menu_proc.Append(wx.ID_ANY, "black").GetId()
        self._id_clr_white = menu_proc.Append(wx.ID_ANY, "white").GetId()
        self._id_clr_random = menu_proc.Append(wx.ID_ANY, "random").GetId()

        # Select the strategy of CPU.
        menu_cpu = wx.Menu()
        self._id_random = menu_cpu.AppendRadioItem(
            wx.ID_ANY, "random").GetId()
        self._id_maximize = menu_cpu.AppendRadioItem(
            wx.ID_ANY, "maximize").GetId()
        self._id_minimize = menu_cpu.AppendRadioItem(
            wx.ID_ANY, "minimize").GetId()
        self._id_minmax = menu_cpu.AppendRadioItem(
            wx.ID_ANY, "min-max").GetId()

        self.Bind(wx.EVT_MENU, self.event_manager)

        self.Append(menu_file, "File")
        self.Append(menu_edit, "Edit")
        self.Append(menu_proc, "Procedure")
        self.Append(menu_cpu, "CPU strategy")

    def save_board(self):
        """Save current board."""
        black_board, white_board, board_log, board_back = \
            self._frame.othello.return_state()
        self._board_save = copy.deepcopy([black_board, white_board])
        self._board_log = copy.deepcopy(board_log)
        self._board_back = copy.deepcopy(board_back)

    def load_board(self):
        """Load saved board."""
        self._frame.othello.load_state(
            self._board_save[0], self._board_save[1],
            self._board_log, self._board_back,
        )

    def initialize_game(self):
        """Initialize board."""
        game = OthelloGame()
        game.load_strategy(Strategy)
        self._frame.othello = game

    def close_game(self):
        """Game over."""
        return self._frame.Close()

    def undo_turn(self):
        """Return to the previous board."""
        return self._frame.othello.undo_turn()

    def redo_turn(self):
        """Redo the last select."""
        return self._frame.othello.redo_turn()

    def change_settings(self, event):
        """Change settings."""
        # Change procedure.
        if event.GetId() == self._id_clr_black:
            game = OthelloGame(player_clr="black")
            game.load_strategy(Strategy)
            self._frame.othello = game
        if event.GetId() == self._id_clr_white:
            game = OthelloGame(player_clr="white")
            game.load_strategy(Strategy)
            self._frame.othello = game
        if event.GetId() == self._id_clr_random:
            game = OthelloGame(player_clr="random")
            game.load_strategy(Strategy)
            self._frame.othello = game

        # Change_strategy.
        if event.GetId() == self._id_random:
            return self._frame.othello.change_strategy("random", False)
        if event.GetId() == self._id_maximize:
            return self._frame.othello.change_strategy("maximize", False)
        if event.GetId() == self._id_minimize:
            return self._frame.othello.change_strategy("minimize", False)
        if event.GetId() == self._id_minmax:
            return self._frame.othello.change_strategy("min-max", False)

    def event_manager(self, event):
        if event.GetId() == wx.ID_SAVE:
            return self.save_board()
        if event.GetId() == wx.ID_REPLACE:
            return self.load_board()
        if event.GetId() == wx.ID_RESET:
            return self.initialize_game()
        if event.GetId() == wx.ID_EXIT:
            return self.close_game()
        if event.GetId() == wx.ID_UNDO:
            return self.undo_turn()
        if event.GetId() == wx.ID_REDO:
            return self.redo_turn()
        return self.change_settings(event)
