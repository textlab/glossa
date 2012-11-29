require "rglossa/engine"

module Rglossa
end

require 'cqp_query_context'
require 'simple_cqp'

# The following should probably be moved to something that is installed via a
# rake task or something that is run for each of the search engines that the
# administrator wants to include. However, since CWB is currently the only
# available search engine and included by default, we leave the configuration
# here for the moment.

# Default registry which is used unless the search request specifies otherwise
#CQPQueryContext::DEFAULT_REGISTRY = /path/to/registry

# CWB command names
SimpleCQP::CQP_CMD = 'cqp'
SimpleCQP::CWB_LEXDECODE_CMD = 'cwb-lexdecode'

SimpleCQP::TEMP_DIR = '/tmp/'