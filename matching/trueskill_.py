"""Calculate rating."""

import pickle

import trueskill


class TrueSkill:
    """
    Load and update TrueSkill ratings.

    Parameters
    ----------
    members : list of str
        List of member names to track their ratings.
    filename : str, optional
        File name to store the rating data.
        Defaults to "./matching/trueskill.pkl".

    Attributes
    ----------
    _filename : str
        File name to store the rating data.
    _rating : dict
        Dictionary to store the TrueSkill ratings of the members.

    Methods
    -------
    save_rating()
        Save the rating data to the specified file.
    update_rating(rating1, rating2, drawn=False)
        Update the TrueSkill ratings of two members after a match.
    initialize_rating()
        Initialize the TrueSkill ratings of all members to the default value.
    printer()
        Print the TrueSkill ratings of all members to the console.
    returner()
        Return the TrueSkill ratings of all members as a tuple of lists.

    """

    def __init__(self, members, filename="./matching/trueskill.pkl"):
        self._filename = filename
        try:
            with open(filename, "rb") as file_:
                self._rating = pickle.load(file_)
        except FileNotFoundError:
            self._rating = {}
        for member in members:
            if member not in self._rating:
                self._rating[member] = trueskill.Rating()

    def save_rating(self):
        """Save the TrueSkill rating data to the specified file."""
        with open(self._filename, "wb") as file_:
            pickle.dump(self._rating, file_)

    def update_rating(
            self, rating1: trueskill.Rating, rating2: trueskill.Rating,
            drawn: bool = False):
        """
        Save the TrueSkill rating data to the specified file.

        Parameters
        ----------
        rating1 : trueskill.Rating
            The winner’s rating if they didn’t draw.
        rating2 : trueskill.Rating
            The loser’s rating if they didn’t draw.
        drawn : bool
            If the players drew, set this to True. Defaults to False.
        """
        self._rating[rating1], self._rating[rating2] = trueskill.rate_1vs1(
            self._rating[rating1], self._rating[rating2], drawn = drawn
        )

    def initialize_rating(self):
        """Initialize the ratings of all members."""
        for member in self._rating.keys():
            self._rating[member] = trueskill.Rating()

    def printer(self):
        """Print the current rating of all members."""
        for key in self._rating:
            print(key, self._rating[key].mu, self._rating[key].sigma)

    def returner(self):
        """
        Return the current rating of all members.

        Returns
        -------
        Tuple[list of str, list of float, list of float]
            A tuple of the list of members, the list of their mus, and the list of their sigmas.
        """
        keys = []
        mus = []
        sigmas = []
        for key in self._rating:
            keys.append(key)
            mus.append(self._rating[key].mu)
            sigmas.append(self._rating[key].sigma)
        return keys, mus, sigmas
