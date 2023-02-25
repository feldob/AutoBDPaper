# -- Params --
# SUT's:
suts =                        [ bytecountsut, bmisut, bmiclasssut, datesut ]
# execution time (seconds):
exectimes =                   [30, 600]
# alorithms:
algorithms =                  [ :lns, :bcs ]
# repetitions:
repetitions  =                20
# sampling strategy:
sss =                          [ BituniformSampling ]
# compatible type sampling investigates the compatible types for an argument, not only the single one defined in the interface
ctss =                         [ true ]

expdir = joinpath("results","2_main_experiment")
doexperiment(expdir, suts, exectimes, algorithms, repetitions, sss, ctss)