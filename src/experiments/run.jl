using Pkg; Pkg.instantiate(); Pkg.activate(".")

using AutoBVA
using AutoBDPaper
using CSV # 6_stats.jl

include("1_sampling_screening.jl")
include("2_main_experiment.jl")
include("3_summary_creation.jl")
include("4_clustering_screening.jl")
include("5_clustering.jl")

# stats
include("6_stats.jl")

include("7_sampled_sut_experiment_all.jl")
