"""A strategy to try to maximize the number of disks you have."""

import random


class Random:
    """A class for randomly putting a disk on the Othello board.

    Attributes:
    -----------
    None

    Methods:
    --------
    put_disk(self, othello):
        Put a disk randomly on the Othello board.

        Parameters:
        -----------
        othello : Othello
            An instance of the Othello class representing the current state of the game.

        Returns:
        --------
        int
            The index of the square where the disk is placed.
    """

    def __init__(self):
        return

    def put_disk(self, othello):
        """Put a disk randomly on the Othello board.

        Parameters:
        -----------
        othello : Othello
            An instance of the Othello class representing the current state of the game.

        Returns:
        --------
        int
            The index of the square where the disk is placed.
        """
        candidates = othello.reversible_area_list(othello.turn)
        return random.choice(candidates)
