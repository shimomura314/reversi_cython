"""A strategy to try to maximize the number of disks you have."""

import random


class Maximize:
    """
    A strategy to try to maximize the number of disks you have.

    Attributes
    ----------
    None

    Methods
    -------
    put_disk(othello):
        Given an Othello game board, finds all the legal moves and chooses a random move that maximizes the number of
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
        max_strategy = []
        max_merit = 0

        candidates = othello.reversible_area_list(turn)
        for candidate in candidates:
            new_board = othello.simulate_play(
                othello.turn, candidate)
            counter = othello.count_disks(*new_board)
            if max_merit < counter[turn]:
                max_strategy = [candidate]
                max_merit = counter[turn]
            elif max_merit == counter[turn]:
                max_strategy.append(candidate)
        return random.choice(max_strategy)
