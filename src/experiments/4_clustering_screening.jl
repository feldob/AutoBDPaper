# trying all different combinations of features for the clustering to find a suitable one for the main experiment

# data frame file:
df_file = joinpath("results", "2_main_experiment", "bytecount_all.csv")

# sutname:
sutname = "bytecount"

# clustering repetitions for result stability
rounds = 100

# base on valid space validity group VV only
VGs = (VV,)

# feature set that is to extract all combinations of at least 2 features
features = ALL_BVA_CLUSTERING_FEATURES

# setup object
setup = ClusteringSetup(df_file, sutname, features; rounds, VGs)

# write to disk
wtd = true

# do the screening of all feature combinations and write results to file
screen(setup; wtd)