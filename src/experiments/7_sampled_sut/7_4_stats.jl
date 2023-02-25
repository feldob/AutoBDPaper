# assumes sutnames and expdir to be globally set

# 2. stats main experiments, quantitative
summary_main_quantitative(expdir)
# 3. stats main experiments, qualitative (i.e. from clustering)
summary_main_qualitative(expdir)

# 4. representative summaries for all suts
summary_cluster_representatives(expdir, AutoBVA.name.(suts))

# 5. latexify all
latexify_summary_quantitative(expdir, "stats_$(expdir[end])_params_quant.tex")
latexify_summary_qualitative(expdir, "stats_$(expdir[end])_params_qual.tex")
latexify_clustering_representatives(expdir, AutoBVA.name.(suts), "stats_$(expdir[end])_params_representatives.tex")

# 6. summary all suts
summary_all_suts(expdir, suts)