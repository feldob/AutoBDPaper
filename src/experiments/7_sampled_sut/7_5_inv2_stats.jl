extract_quantitative_summary_julia_base("results", "summary_" * e_dir, "summary_" * ne_dir)
latexify_quantitative_summary_julia_base("results")

extract_top_clusterings_julia_base("results", "summary_" * e_dir, "summary_" * ne_dir)
latexify_juliabase_top_silhouettes("results")

extract_clustering_stats_julia_base("results", "summary_" * e_dir, "summary_" * ne_dir)
latexify_silhouette_stats_julia_base("results")

latexify_juliabase_clusters_per_silhouettescore("results", "summary_" * e_dir, "summary_" * ne_dir)