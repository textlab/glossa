(ns cglossa.search-engines
  "Require namespaces containing implementations for various search engines
  here in order to register any multimethod implementations found in those
  namespaces."
  (:require cglossa.search-views.cwb.core
            cglossa.search-views.fcs.core
            cglossa.result-views.cwb.core
            cglossa.result-views.fcs.core))
