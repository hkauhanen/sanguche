# Grambank features we are interested in

wo_features = ["GB130", "GB065", "GB193", "GB025", "GB024", "VO"]#, "NRc", "PN"]
control_features = ["GB030", "GB302"]
features = vcat(wo_features, control_features)

# the features VO, PN and NRc need to be "reconstructed":
wo_features_original = ["GB130", "GB132", "GB065", "GB193", "GB025", "GB024", "GB131", "GB133", "GB327", "GB328", "GB074", "GB075"]
features_original = vcat(wo_features_original, control_features)
