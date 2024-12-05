# neighbourhood sizes
#degrees = Int.(unique(round.(exp.(range(log(1), stop=log(200), length=22)))))
#degrees = [10]   ### uncomment for debugging purposes
degrees = 1:500

# WALS features we are interested in
wo_features = ["87A", "86A", "85A", "88A", "89A", "83A", "90A", "82A"]
#control_features_wals = ["10A", "129A"]
control_features_wals = ["112A", "116A"]
#features_wals = vcat(wo_features, control_features_wals)
features_wals = wo_features

# Grambank features we are interested in
wo_features = ["GB130", "GB065", "GB025", "GB024", "VO", "NRc", "PN", "NA"]
control_features_grambank = ["GB030", "GB302"]
#control_features_grambank = ["GB059", "GB068"]
#features_grambank = vcat(wo_features, control_features_grambank)
features_grambank = wo_features
