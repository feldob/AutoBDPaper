# execution time (seconds):
exectimes =                   [30]
# alorithms:
algorithms =                  [ :lns, :bcs ]
# repetitions:
repetitions  =                10
# sampling strategy:
sss =                          [ BituniformSampling ]
# compatible type sampling investigates the compatible types for an argument, not only the single one defined in the interface
ctss =                         [ true ]

doexperiment(expdir, suts, exectimes, algorithms, repetitions, sss, ctss)
