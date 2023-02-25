load_samples()

function runallexps()
    include("7_sampled_sut/7_1_sampled_sut_experiment.jl")
    include("7_sampled_sut/7_2_summary_creation.jl")
    include("7_sampled_sut/7_3_clustering.jl")
    include("7_sampled_sut/7_4_stats.jl")
end

# preprocess methods, as there are erronerous ones
# 36 functions failed.
problematic_functions = [  "binomial", # "killed" (2)
                            "exit",     # exits the program (1)
                            "lpad",     # "killed" (2)
                            "rpad",     # "killed" (2)
                            "rand",     # "killed" (1)
                            "sqrt",     # "ArgumentError : buffer size" (1)
                            "getindex",
                            "_lift_one_interp_helper",
                            "_methods_by_ftype", # (3 ne) killed
                            "_overflowind", # (3 ne) never returns
                            "range_step_stop_length", # (3 ne) long error message going back to sut
                            "range_start_step_length", # (3 ne) long error message going back to sut
                            "_extrema_rf",
                            "setup_chnl_and_tasks", # (3 ne) Killed
                            "_negdims", # (2 ne) Killed
                            "_oidd_nextind", # (2 ne) segmentation fault,
                            "StringVector", # (1 ne) Killed
                            "_rf_findmin",
                            "_rf_findmax",
                            "ast_slotflag", # (2 ne) signal (11): Segmentation fault
                            "_string_n", # (1 ne) buffer size error
                            "ndigits0znb", # (2 ne) weird error print
                            "ndigits0zpb", # (2 ne) weird error print
                            "check_count",
                            "ntupleany", # (1 ne) killed
                            "range_start_length", # "(2 ne) unexact error -1232 -> UInt32"
                            "range_stop_length", # "(2 ne) unexact error -1232 -> UInt32"
                            "number_from_hex", # (1 ne) ERROR: 2128029027
                            "setup_chnl_and_tasks", # (2 ne) error
                            "runtests", # (1 ne), error
                            "slug",
                            "summarysize", # (1 ne) killed
                            "try_yieldto", # (1 ne) segmentation fault
                            "unpreserve_handle", # (1 ne) endless void
                            "valid_import_path", # (1 ne) killed
                            "#s78#210"
                            ]

function run_bve_on(jmethods::Vector, expdirstart::String)
    for selection in jmethods
        selection = filter(s -> AutoBDPaper.name(s) ∉ problematic_functions, selection)
        global suts = map(f -> SUT(f.f, f.m), selection)
        foreach(sut -> bve_suts[AutoBVA.name(sut)] = sut, suts)
        global expdir = joinpath("results", expdirstart * "$(numargs(suts[1]))")
        runallexps()
    end

    combine_all_direct_stats(expdirstart)
    combine_all_clusters_stats(expdirstart)
    combine_all_silhouettes(expdirstart)
    mv_representatives_to_summary(expdirstart)
    mv_tex_to_summary(expdirstart)
end

e_dir = "7_sampled_sut_experiment_"
ne_dir = "7_sampled_sut_experiment_ne_"

# number of suts in investigation
failings_suts = 36 # see above, evaluated but failed AutoBVA
filtered_out_suts = 20 # too low level: (~), (!=), (!==), (&), (|), (+), (-), (^), (\), (/), (*), (<), (>), (//), (<<), (>>), (>>>), (==), (<=), (>=)

overall_suts = sum(length.([methods_ints_1, methods_ints_2, methods_ints_3, methods_ints_ne_1, methods_ints_ne_2, methods_ints_ne_3]))
successfully_investigated = overall_suts - failings_suts - filtered_out_suts

overall_functions = unique(map(jm -> jm.f,vcat([methods_ints_1, methods_ints_2, methods_ints_3, methods_ints_ne_1, methods_ints_ne_2, methods_ints_ne_3]...)))

run_bve_on([ methods_ints_1, methods_ints_2, methods_ints_3 ], e_dir)
run_bve_on([ methods_ints_ne_1, methods_ints_ne_2, methods_ints_ne_3 ], ne_dir)

# combining stats from both batches
include("7_sampled_sut/7_5_inv2_stats.jl")