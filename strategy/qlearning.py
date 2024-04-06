from numba import jit
import pickle
import random
# import threading


class QLearning:
    """
    Q-learning is a reinforcement learning algorithm
    that seeks to learn the optimal policy for an agent to take in an environment.
    This class implements the Q-learning algorithm for a given environment and state-action space.

    Parameters:
    -----------
    alpha : float, optional (default=0.1)
        Learning rate for the Q-value update.
    gamma : float, optional (default=0.99)
        Discount factor for future rewards.
    epsilon : float, optional (default=0.1)
        Epsilon-greedy policy parameter.

    Attributes:
    -----------
    q_table : dict
        Q-value table.

    Methods:
    --------
    choose_action(state)
        Choose an action based on the epsilon-greedy policy.
    update(state, action, reward, next_state)
        Update the Q-value table based on the reward received and the next state.
    """

    def __init__(self, alpha=0.5, gamma=0.9, epsilon=0.1, Q_values=None):
        """
        Initializes the QLearning object with the given parameters.

        Parameters:
        -----------
        alpha : float, optional (default=0.1)
            Learning rate for the Q-value update.
        gamma : float, optional (default=0.99)
            Discount factor for future rewards.
        epsilon : float, optional (default=0.1)
            Epsilon-greedy policy parameter.
        """
        self._save_path = ".//strategy//QL_dict//my_dict-%s-%s-%s.pickle" % (
            str(alpha), str(gamma), str(epsilon)
        )
        self._ALPHA = alpha
        self._GAMMA = gamma
        self._EPSILON = epsilon

        if Q_values is None:
            try:
                with open(self._save_path, "rb") as f:
                    self._Q_values = pickle.load(f)
            except:
                self._Q_values = {}
        else:
            self._Q_values = Q_values

        self._EXP2 = (
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
        )

    def save_dict(self):
        """Write dictionary on files."""
        with open(self._save_path, "wb") as f:
            pickle.dump(self._Q_values, f)

    def return_dict(self):
        """Return dictionary on files."""
        return self._Q_values

    def update_q_value(self, state, action, reward, next_state):
        """
        Updates the Q-value for a given state-action pair using the Q-Learning algorithm.

        Parameters:
        -----------
        state : tuple
            Current state of the agent.
        action : int
            Action taken by the agent.
        reward : float
            Reward received by the agent.
        next_state : tuple
            Next state of the agent.
        """
        if self._turn == 0:
            possible_actions = self._othello.reversible_area_list(
                self._turn ^ 1, next_state[0], next_state[1])
        else:
            possible_actions = self._othello.reversible_area_list(
                self._turn ^ 1, next_state[1], next_state[0])

        if possible_actions != []:
            max_q_next_state = -1 * max(
                [self._Q_values.get((next_state, a), 0) for a in possible_actions])
        else:
            max_q_next_state = -1 * self._Q_values.get((next_state, action), 0)
        q_value = self._Q_values.get((state, action), 0)
        # Q(s, a) = Q(s, a) + α(r + γmaxQ(s', a') - Q(s, a))
        self._Q_values[(state, action)] = \
            (1 - self._ALPHA) * q_value + self._ALPHA * (reward + self._GAMMA*max_q_next_state)

    def select_action(self, state, possible_actions):
        """
        Select an action for the current state according to the epsilon-greedy policy.

        Parameters
        ----------
        state : tuple
            The current state of the environment.
        possible_actions : List[int]
            A list of possible actions for the current state.

        Returns
        -------
        int
            The selected action.
        """
        if random.random() < self._EPSILON:
            return random.choice(possible_actions)
        else:
            q_values = {
                a: self._Q_values.get((state, a), 0)
                for a in possible_actions}
            if all(q == 0 for q in q_values):
                return random.choice(self._possible_actions)
            max_q_value = max(q_values.values())
            return random.choice(
                [a for a, q in q_values.items() if q == max_q_value])

    def put_disk(self, othello):
        """
        Put a disk on the board according to the action.

        Parameters
        ----------
        othello : Othello
            The current state of the Othello game.

        Returns
        -------
        int
            The selected action.
        """
        self._turn = othello.turn
        self._othello = othello

        self._possible_actions = self._othello.reversible_area_list(self._turn)

        # [player, opponent]
        state = self._othello.return_player_board(self._turn)

        # Decide next action
        action = self.select_action(state, self._possible_actions)
        next_state = self._othello.simulate_play(self._turn, action)

        if self._turn == 0:
            # Judge game.
            player, opponent = self._othello.count_disks(
                next_state[0], next_state[1])
            black = self._othello.reversible_area(
                0, next_state[0], next_state[1])
            white = self._othello.reversible_area(
                1, next_state[0], next_state[1])
        else:
            # Judge game.
            player, opponent = self._othello.count_disks(
                next_state[1], next_state[0])
            black = self._othello.reversible_area(
                0, next_state[1], next_state[0])
            white = self._othello.reversible_area(
                1, next_state[1], next_state[0])

        reward = 0
        if (black == 0 and white == 0) or (player+opponent) == 64:
            reward = player - opponent

        self.update_q_value(state, action, reward, next_state)
        return action
