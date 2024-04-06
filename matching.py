"""Calculate rating."""

from concurrent.futures import ProcessPoolExecutor
import cProfile
from itertools import combinations
from tqdm import tqdm

import matplotlib.pyplot as plt

from bitboard import OthelloGame
from matching import EloRating
from strategy import Strategy

repeat = 10
STRAT = [
    "random",
    "maximize",
    "minimize",
    "min-max short",
    "min-max",
    "min-max long",
]

# [win, lose, draw]
Rating = EloRating(STRAT)
rslts = []

parameters = []
for _ in range(repeat):
    for strategy1, strategy2 in combinations(STRAT, 2):
        parameters.append((strategy1, strategy2))
progress_bar = tqdm(total=len(parameters))


def update_cnt(rslt_cnt, rslt):
    if rslt == "WIN":
        rslt_cnt[0] += 1
    if rslt == "LOSE":
        rslt_cnt[1] += 1
    if rslt == "DRAW":
        rslt_cnt[2] += 1
    return rslt_cnt


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

    rslt_cnt = [0, 0, 0]

    rslt = set_match(strategy1, strategy2, "black")
    rslt_cnt = update_cnt(rslt_cnt, rslt)

    rslt = set_match(strategy1, strategy2, "white")
    rslt_cnt = update_cnt(rslt_cnt, rslt)
    return strategy1, strategy2, 2, rslt_cnt[0] + rslt_cnt[2]/2


def runMP(plot=False):
    if plot:
        cnt = 0
        fig = plt.figure()
        plt.bar(
            list(range(len(Rating._rating.values()))),
            Rating._rating.values())
        plt.ylim([1000, 2000])

    with ProcessPoolExecutor(max_workers=8) as executor:
        for rslt in executor.map(matching, parameters):
            Rating.update_rating(*rslt)
            progress_bar.update(1)
            if plot:
                cnt += 1
                if cnt < 10:
                    continue
                cnt = 0
                plt.cla()
                plt.bar(
                    list(range(len(Rating._rating.values()))),
                    Rating._rating.values())
                plt.ylim([1000, 2000])
                plt.pause(.01)

    Rating.save_rating()
    progress_bar.close()
    print(Rating._rating)
    print("Game was played", len(parameters)*2, "times.")


def runby1():
    for parameter in parameters:
        rslt = matching(parameter)
        Rating.update_rating(*rslt)
        progress_bar.update(1)

    Rating.save_rating()
    progress_bar.close()
    print(Rating._rating)
    print("Game was played", len(parameters)*2, "times.")


if __name__ == "__main__":
    runMP(plot=True)
    # runby1()
    # cProfile.run("runby1()", filename="./matching/matching.prof", sort=2)
