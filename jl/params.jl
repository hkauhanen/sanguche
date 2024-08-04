# neighbourhood size (a quasilogarithmic sequence of integers from 1 to 200)
degrees = Int.(unique(round.(exp.(range(log(1), stop=log(200), length=22)))))
#degrees = [10]   ### uncomment for debugging purposes

# WALS features we are interested in
wo_features = ["87A", "86A", "85A", "88A", "89A", "83A", "90A", "82A"]
control_features_wals = ["10A", "129A"]
features_wals = vcat(wo_features, control_features_wals)

# Grambank features we are interested in
wo_features = ["GB130", "GB065", "GB193", "GB025", "GB024", "VO", "NRc", "PN"]
control_features_grambank = ["GB030", "GB302"]
features_grambank = vcat(wo_features, control_features_grambank)

