"""Various strategies for othello."""

from .maximize import Maximize
from .minimize import Minimize
from .minmaxcalc import MinmaxC
from .qlearning import QLearning
from .random import Random


class Strategy:
    """
    A class representing a strategy for playing Othello.

    Attributes:
    -----------
    _othello : OthelloGame
        An Othello game instance.
    _player_clr : int
        The color of the player to move.
    _strategy : object
        An object representing a strategy for putting a disk on the board.

    Methods:
    --------
    set_strategy(strategy: str) -> None
        Sets the strategy for putting a disk on the board.
    selecter(othello: OthelloGame) -> int
        Chooses a position to put a disk on the board using the current strategy.
    """

    def __init__(self, othello, strategy: str = "random"):
        """
        Initializes an instance of the Strategy class.

        Parameters:
        -----------
        othello : OthelloGame
            An Othello game instance.
        strategy : str, optional
            The name of the strategy to use, by default "random".
        """
        self.set_strategy(strategy)

    def set_strategy(self, strategy: str, **kwargs):
        """
        Sets the strategy for putting a disk on the board.

        Parameters:
        -----------
        strategy : str
            The name of the strategy to use.
        """
        if strategy == "random":
            self._strategy = Random()
        elif strategy == "maximize":
            self._strategy = Maximize()
        elif strategy == "minimize":
            self._strategy = Minimize()
        elif strategy == "min-max short":
            self._strategy = MinmaxC(2)
        elif strategy == "min-max":
            self._strategy = MinmaxC(4)
        elif strategy == "min-max long":
            self._strategy = MinmaxC(6)
        elif strategy == "QLearning":
            self._strategy = QLearning(**kwargs)
        else:
            raise KeyError

    def selecter(self, othello):
        """
        Chooses a position to put a disk on the board using the current strategy.

        Parameters:
        -----------
        othello : OthelloGame
            An Othello game instance.

        Returns:
        --------
        int
            An integer representing the position to put a disk on the board.
        """
        return self._strategy.put_disk(othello)
