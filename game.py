"""
オセロアプリを起動するためのファイル.
    - bitbord : オセロの手続きを設定
    - display : GUIを設定
    - strategy : CPUの戦略を定義
pyinstaller game.py --onefile --noconsoleでexe化
"""

from logging import basicConfig, DEBUG

import wx

from bitboard import OthelloGame
from display import MyFrame
from strategy import Strategy

# basicConfig(
#     filename="logger.txt", level=DEBUG,
#     format="%(asctime)s - %(levelname)s - %(module)s - %(message)s",
# )


if __name__ == "__main__":
    game = OthelloGame()
    game.load_strategy(Strategy)

    application = wx.App()
    frame = MyFrame(title="Othello Game", othello=game)

    frame.Center()
    frame.Show()
    application.MainLoop()
    wx.Exit()
