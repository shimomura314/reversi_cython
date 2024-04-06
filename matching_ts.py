"""Calculate rating."""

from concurrent.futures import ProcessPoolExecutor
import cProfile
from itertools import combinations
from tqdm import tqdm

import matplotlib.pyplot as plt

from bitboard import OthelloGame
from matching import TrueSkill
from strategy import Strategy

repeat = 3
STRAT = [
    "random",
    "maximize",
    "minimize",
    "min-max short",
    "min-max",
    "min-max long",
]

Rating = TrueSkill(STRAT)

parameters = []
for _ in range(repeat):
    for strategy1, strategy2 in combinations(STRAT, 2):
        parameters.append((strategy1, strategy2))
progress_bar = tqdm(total=len(parameters))


def set_match(strategy1, strategy2, color):
    game = OthelloGame(color)
    game.load_strategy(Strategy)
    game.change_strategy(strategy1, is_player=True)
    game.change_strategy(strategy2, is_player=False)
    game.auto_mode(True)
    while True:
        fin, _ = game.process_game()
        if fin:
            break
    return game.result


def matching(strategies):
    """Returns the number of strategy1's result.

    Parameters
    ----------
    strategies : list of str
        Names of used strategies.

    matching_number : int
        Number of matches.

    Returns
    ----------
    count_win, count_lose, count_draw : list
        result of matches.
    """
    (strategy1, strategy2) = strategies
    if strategy1 == strategy2:
        return

    win = 0
    lose = 0
    drew = 0

    rslt = set_match(strategy1, strategy2, "black")
    if rslt == "WIN":
        win += 1
    if rslt == "LOSE":
        lose += 1
    if rslt == "DRAW":
        drew += 1

    rslt = set_match(strategy1, strategy2, "white")
    if rslt == "WIN":
        win += 1
    if rslt == "LOSE":
        lose += 1
    if rslt == "DRAW":
        drew += 1

    return strategy1, strategy2, win, lose, drew


def printer(Rating: TrueSkill):
    keys, mus, sigmas = Rating.returner()

    plt.bar(list(range(len(mus))), mus, yerr=sigmas)
    plt.ylim([20, 35])
    # plt.ylim([min(mus)-5, max(mus)+5])
    plt.xticks(list(range(len(mus))), keys)


def runMP(plot=False):
    if plot:
        cnt = 0
        fig = plt.figure()

    with ProcessPoolExecutor(max_workers=8) as executor:
        for rslt in executor.map(matching, parameters):
            # Update Rating.
            strategy1, strategy2, win, lose, drew = rslt
            for _ in range(win):
                Rating.update_rating(strategy1, strategy2)
            for _ in range(lose):
                Rating.update_rating(strategy2, strategy1)
            for _ in range(drew):
                Rating.update_rating(strategy1, strategy2, True)

            progress_bar.update(1)
            if plot:
                cnt += 1
                if cnt < 10:
                    continue
                cnt = 0
                plt.cla()
                printer(Rating)
                plt.pause(.01)

    Rating.save_rating()
    progress_bar.close()
    Rating.printer()
    print("Game was played", len(parameters)*2, "times.")


def runby1():
    for parameter in parameters:
        rslt = matching(parameter)
        # Update Rating.
        strategy1, strategy2, win, lose, drew = rslt
        for _ in range(win):
            Rating.update_rating(strategy1, strategy2)
        for _ in range(lose):
            Rating.update_rating(strategy2, strategy1)
        for _ in range(drew):
            Rating.update_rating(strategy1, strategy2, True)
        progress_bar.update(1)

    Rating.save_rating()
    progress_bar.close()
    Rating.printer()
    print("Game was played", len(parameters)*2, "times.")


if __name__ == "__main__":
    # runMP(plot=True)
    # runby1()
    cProfile.run("runby1()", filename="./matching/matching.prof", sort=2)
