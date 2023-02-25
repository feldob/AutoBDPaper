# -- Params --
# SUT's:
suts =                        [ bytecountsut ]
# execution time (seconds):
exectimes =                   [30, 60]
# alorithms:
algorithms =                  [ :lns, :bcs ]
# repetitions:
repetitions  =                20
# sampling strategy:
sss =                          [ UniformSampling, BituniformSampling ]
# compatible type sampling investigates the compatible types for an argument, not only the single one defined in the interface
ctss =                         [ true, false ]

expdir = joinpath("results","1_sampling_screening")
doexperiment(expdir, suts, exectimes, algorithms, repetitions, sss, ctss)