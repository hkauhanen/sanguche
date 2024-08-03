# neighbourhood size
degrees = vcat(1:9, 10:10:100, 200)
#degrees = [10]   ### uncomment for debugging purposes

# WALS features we are interested in
wo_features = ["87A", "86A", "85A", "88A", "89A", "83A", "90A", "82A"]
control_features = ["10A", "129A"]
features_wals = vcat(wo_features, control_features)

# Grambank features we are interested in
wo_features = ["GB130", "GB065", "GB193", "GB025", "GB024", "VO", "NRc", "PN"]
control_features = ["GB030", "GB302"]
features_grambank = vcat(wo_features, control_features)

