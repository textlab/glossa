(ns cglossa.search-engines
  "Require namespaces containing implementations for various search engines
  here in order to register any multimethod implementations found in those
  namespaces."
  (:require cglossa.search.cwb.shared
            cglossa.search.cwb.speech
            cglossa.search.cwb.multi))
