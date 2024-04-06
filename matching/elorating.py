"""Calculate rating."""

import pickle


class EloRating:
    """
    This class implements the Elo rating algorithm
    for ranking members of a group based on their win-lose records.

    Parameters
    ----------
    members : list of str
        A list of the names of the members to be rated.
    filename : str, optional
        The name of the file to save the rating data,
        by default "./matching/strategy_rating.pkl"

    Attributes
    ----------
    INIT_RATING : int
        The initial rating for a new member, set to 1500.
    K : int
        The rating adjustment constant, set to 16.
    _filename : str
        The name of the file to save the rating data.
    _rating : dict
        A dictionary that stores the rating data for each member,
        where the keys are the member names and the values are their ratings.

    Methods
    -------
    save_rating()
        Save the rating data to a file.
    win_lose_ratio(member1, member2)
        Calculate the win-lose ratio between two members.
    update_rating(member1, member2, number_game, cnt_mbr1_win)
        Update the rating of two members based on the results of a match.
    initialize_rating()
        Initialize the rating data for all members to the default value.
    """
    INIT_RATING = 1500
    K = 16

    def __init__(self, members, filename="./matching/strategy_rating.pkl"):
        """
        Initializes the EloRating object.

        Parameters
        ----------
        members : list of str
            A list of the names of the members to be rated.
        filename : str, optional
            The name of the file to save the rating data,
            by default "./matching/strategy_rating.pkl"
        """
        self._filename = filename
        try:
            with open(filename, "rb") as file_:
                self._rating = pickle.load(file_)
        except FileNotFoundError:
            self._rating = {}
        for member in members:
            if member not in self._rating:
                self._rating[member] = EloRating.INIT_RATING

    def save_rating(self):
        """Save the rating data to a file."""
        with open(self._filename, "wb") as file_:
            pickle.dump(self._rating, file_)

    def win_lose_ratio(self, member1: str, member2: str):
        """
        Calculate the win-lose ratio between two members.

        Parameters
        ----------
        member1 : str
            The name of the first member.
        member2 : str
            The name of the second member.

        Returns
        -------
        float
            The win-lose ratio of member1 against member2.
        """
        rate_difference = self._rating[member2]-self._rating[member1]
        ratio = 1/(pow(10, rate_difference/400)+1)
        return ratio

    def update_rating(
            self, member1: str, member2: str,
            number_game: int, cnt_mbr1_win: int,
            ):
        """
        Update the rating of two members based on the results of a match.

        Parameters
        ----------
        member1 : str
            The name of the first member.
        member2 : str
            The name of the second member.
        number_game : int
            The total number of games played.
        cnt_mbr1_win : int
            The number of games member1 won.
        """
        cnt_mbr2_win = number_game - cnt_mbr1_win
        pre_prblty_1 = self.win_lose_ratio(member1, member2)
        expected_win_1 = pre_prblty_1 * number_game
        pre_prblty_2 = self.win_lose_ratio(member2, member1)
        expected_win_2 = pre_prblty_2 * number_game

        self._rating[member1] = (
            self._rating[member1]
            + EloRating.K * (cnt_mbr1_win - expected_win_1)
        )
        self._rating[member2] = (
            self._rating[member2]
            + EloRating.K * (cnt_mbr2_win - expected_win_2)
        )

    def initialize_rating(self):
        for member in self._rating.keys():
            self._rating[member] = EloRating.INIT_RATING
