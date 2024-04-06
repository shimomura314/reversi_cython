"""A strategy to try to minimize the number of disks you have."""

import random


class Minimize:
    """
    A strategy to try to maximize the number of disks you have.

    Attributes
    ----------
    None

    Methods
    -------
    put_disk(othello):
        Given an Othello game board, finds all the legal moves and chooses a random move that minimizes the number of
        disks owned by the current player.

    Parameters
    ----------
    othello : instance of the Othello class
        The current game state

    Returns:
    --------
    int : the index of the chosen move
    """

    def __init__(self):
        pass

    def put_disk(self, othello):
        turn = othello.turn
        min_strategy = []
        min_merit = float("inf")

        candidates = othello.reversible_area_list(turn)
        for candidate in candidates:
            new_board = othello.simulate_play(
                othello.turn, candidate)
            counter = othello.count_disks(*new_board)
            if min_merit > counter[turn]:
                min_strategy = [candidate]
                min_merit = counter[turn]
            elif min_merit == counter[turn]:
                min_strategy.append(candidate)
        return random.choice(min_strategy)
