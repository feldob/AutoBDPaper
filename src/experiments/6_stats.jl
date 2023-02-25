# 1. stats of the screening
summary_screening(joinpath("results","1_sampling_screening"))

expdir = joinpath("results","2_main_experiment")
# 2. stats main experiments, quantitative
summary_main_quantitative(expdir)
# 3. stats main experiments, qualitative (i.e. from clustering)
summary_main_qualitative(expdir)

# 4. representative summaries for all suts
summary_cluster_representatives(expdir, AutoBDPaper.sutnames)

# 5. latexify all
latexify_screening()
latexify_summary_quantitative(expdir)
latexify_clustering_screening_scores()
latexify_summary_qualitative(expdir)
latexify_clustering_representatives(expdir)
latexify_summary_cluster_quality(expdir)