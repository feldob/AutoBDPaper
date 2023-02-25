module AutoBDPaper

    using BlackBoxOptim, # framework the detection is built upon
        AutoBVA,    # detection and summarization utilities
        Dates,      # for the Date sut
        Printf,     # for bytecount and bmi suts
        CSV,        # i/o, experimentsummary.jl
        Latexify,   # documentation, publication
        Statistics, # stats.jl -> mean
        DataFrames,  # results + i/o
        Distributions, # detection_stats.jl, sample
        InteractiveUtils   # subtypes

    # loop.jl
    export doexperiment,

    # suts.jl
        bytecountsut, bmiclasssut, bmisut, datesut, sutnames, bve_suts,

    # experimentsummary
        singlefilesummary,

    # detection_stats.jl
        summary_screening, summary_main_quantitative,

    # clustering_stats.jl
        summary_main_qualitative,
        summary_cluster_representatives,

    # latexify_stats.jl
        latexify_screening,
        latexify_summary_quantitative,
        latexify_clustering_screening_scores,
        latexify_summary_qualitative,
        latexify_clustering_representatives,
        latexify_quantitative_summary_julia_base,
        latexify_summary_cluster_quality,
        latexify_silhouette_stats_julia_base,
        latexify_juliabase_top_silhouettes,
        latexify_juliabase_clusters_per_silhouettescore,

    # Base stats
        summary_all_suts, combine_all_silhouettes, mv_representatives_to_summary, mv_tex_to_summary,
        combine_all_direct_stats,
        combine_all_clusters_stats,

    # util
        sutnameof, algof, timeof,

    # stats for investigation 2
        GST,
        extract_quantitative_summary_julia_base,
        extract_top_clusterings_julia_base,
        extract_clustering_stats_julia_base,

    # julia base functionality to get hold of all SUTs
        jmethods, compatibletypes, JMethod, args, name,

        methods_ints_1, methods_ints_2, methods_ints_3,
    
        methods_ints_ne_1, methods_ints_ne_2, methods_ints_ne_3,
        
        load_samples#, most_general

    include("suts.jl") # loads the software/programs under test
    include("loop.jl") # loads the execution loop
    include("julia_base_functions.jl") # loads Julia Base functions for investigation 2
    include("stats/experimentsummary.jl")
    include("stats/detection_stats.jl")
    include("stats/clustering_stats.jl")
    include("stats/latexify_stats.jl")
    include("stats/overall_stats.jl")

end # module
