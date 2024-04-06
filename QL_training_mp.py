"""Calculate rating."""

from concurrent.futures import ProcessPoolExecutor
from itertools import combinations
import multiprocessing
import pickle
from tqdm import tqdm

import matplotlib.pyplot as plt
import numpy as np

from bitboard import OthelloGame
from matching import TrueSkill
from strategy import Strategy


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
    (strategy1, strategy2, Q_values) = strategies
    if strategy1 == strategy2:
        return

    win = 0
    lose = 0
    drew = 0

    for color in ["black", "white"]:
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

        if game.result == "WIN":
            win += 1
        elif game.result == "LOSE":
            lose += 1
        elif game.result == "DRAW":
            drew += 1

    return strategy1, strategy2, win, lose, drew


def printer(Rating: TrueSkill):
    keys, mus, sigmas = Rating.returner()

    plt.bar(list(range(len(mus))), mus, yerr=sigmas)
    plt.ylim([min(mus)-5, max(mus)+5])
    plt.xticks(list(range(len(mus))), keys)


def runMP(plot=False, Q_values=None):
    repeat = 10000
    STRAT = [
        "random",
        "QLearning",
    ]

    Rating = TrueSkill(STRAT, filename="./matching/trueskill4QL.pkl")

    try:
        with open(".//strategy//QL_dict//my_dict-0.5-0.9-0.1.pickle", "rb") as f:
            Q_values = pickle.load(f)
    except:
        Q_values = {}

    if plot:
        cnt = 0
        fig = plt.figure()

    with multiprocessing.Manager() as manager:
        Q_values_ = manager.dict(Q_values)

        parameters = []
        for _ in range(repeat):
            for strategy1, strategy2 in combinations(STRAT, 2):
                parameters.append((strategy1, strategy2, Q_values_))
        progress_bar = tqdm(total=len(parameters))

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
                    if cnt < 5000:
                        continue
                    cnt = 0
                    plt.cla()
                    printer(Rating)
                    plt.pause(.01)

                    with open("./strategy/QL_dict/averageQ.txt", "a") as log:
                        log.write(
                            str(np.average(np.array(
                            [value for value in Q_values.values()]
                            ))) + "\n")

        Rating.save_rating()
        progress_bar.close()
        Rating.printer()
        with open(".//strategy//QL_dict//my_dict-0.5-0.9-0.1.pickle", "wb") as f:
            pickle.dump(Q_values_, f)
        print("Game was played", len(parameters)*2, "times.")


if __name__ == "__main__":
    runMP(plot=True)
