import pstats
sts = pstats.Stats("./matching/matching.prof")
sts.strip_dirs().sort_stats(1).print_stats()

# ncalls: 呼び出し回数
# tottime: subfunctionの実行時間を除いた時間
# percall: tottimeをncallsで割った値
# cumtime: この関数とそのsubfuntionに消費された累積時間
# percall: cumtimeを呼び出し回数で割った値
