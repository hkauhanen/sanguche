# neighbourhood sizes
degrees = 100:50:2000
#degrees = [650, 850]

# WALS features we are interested in
features_wals = ["87A", "86A", "85A", "88A", "89A", "83A", "90A", "82A", "PolQ", "NegM"]
features_wals_pre_preprocessing = ["87A", "86A", "85A", "88A", "89A", "83A", "90A", "82A", "112A", "116A"]
control_features_wals = ["PolQ", "NegM"]

# Grambank features we are interested in
features_grambank = ["GB130", "GB065", "GB025", "GB024", "VO", "GB328", "GB074", "NA", "AdPo", "CoA"]
features_grambank_pre_preprocessing = ["GB130", "GB131", "GB132", "GB133", "GB074", "GB065", "GB193", "GB025", "GB024", "GB328", "GB059", "GB068"]
#control_features_grambank = ["GB030", "GB302"]
control_features_grambank = ["AdPo", "CoA"]


# the following objects are used (later) to pretty-print feature pairs
#

fPairs_wals = ["82A" => "VS",
               "83A" => "VO",
               "85A" => "PN",
               "86A" => "NG",
               "87A" => "NA",
               "88A" => "ND",
               "89A" => "NNum",
               "90A" => "NRc"]

fDict_wals = Dict(fPairs_wals)

features_wals_pretty = copy(features_wals)
[replace!(features_wals_pretty, p) for p in fPairs_wals]


fPairs_grambank = ["GB130" => "VS",
                   "GB065" => "NG",
                   "GB025" => "ND",
                   "GB024" => "NNum",
                   "GB074" => "PN",
                   "GB328" => "NRc",
                   "GB059" => "AdPo",
                   "GB068" => "CoA"]

fDict_grambank = Dict(fPairs_grambank)

features_grambank_pretty = copy(features_grambank)
[replace!(features_grambank_pretty, p) for p in fPairs_grambank]


