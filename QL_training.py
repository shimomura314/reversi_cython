"""Calculate rating."""

import cProfile
from itertools import combinations
import pickle
from tqdm import tqdm

import matplotlib.pyplot as plt
import numpy as np

from bitboard import OthelloGame
from matching import TrueSkill
from strategy import Strategy


def set_match(strategy1, strategy2, color):
    global Q_values

    game = OthelloGame(color)
    game.load_strategy(Strategy)
    if strategy1 == "QLearning":
        game.change_strategy(strategy1, is_player=True, Q_values=Q_values)
    else:
        game.change_strategy(strategy1, is_player=True)
    if strategy2 == "QLearning":
        game.change_strategy(strategy2, is_player=False, Q_values=Q_values)
    else:
        game.change_strategy(strategy2, is_player=False)
    game.auto_mode(True)
    while True:
        fin, _ = game.process_game()
        if fin:
            break

    if strategy1 == "QLearning":
        Q_values = game._strategy_player._strategy.return_dict()
    else:
        Q_values = game._strategy_opponent._strategy.return_dict()

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
    plt.ylim([min(mus)-5, max(mus)+5])
    plt.xticks(list(range(len(mus))), keys)


def runby1():
    repeat = 100000
    STRAT = [
        "random",
        "QLearning",
    ]

    Rating = TrueSkill(STRAT, filename="./matching/trueskill4QL.pkl")

    parameters = []
    for _ in range(repeat):
        for strategy1, strategy2 in combinations(STRAT, 2):
            parameters.append((strategy1, strategy2))
    progress_bar = tqdm(total=len(parameters))

    global Q_values
    try:
        with open(".//strategy//QL_dict//my_dict-0.5-0.9-0.1.pickle", "rb") as f:
            Q_values = pickle.load(f)
    except:
        Q_values = {}

    for i, parameter in enumerate(parameters):
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

        # It takes long time for proccessing.
        if i % 5000 == 0:
            with open("./strategy/QL_dict/averageQ.txt", "a") as log:
                length = "{:>15}".format(len(Q_values.values()))
                ave = str(np.average(np.array(
                    [value for value in Q_values.values()])))
                log.write(length + ", " + ave + "\n")

    Rating.save_rating()
    progress_bar.close()
    Rating.printer()

    with open(".//strategy//QL_dict//my_dict-0.5-0.9-0.1.pickle", "wb") as f:
        pickle.dump(Q_values, f)
    print("Game was played", len(parameters)*2, "times.")


if __name__ == "__main__":
    runby1()
    # cProfile.run("runby1()", filename="./matching/matching.prof", sort=2)
