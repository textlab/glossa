require 'lib/cqp_query_context'
require 'lib/simple_cqp'

# Default registry which is used unless the search request specifies otherwise
#CQPQueryContext::DEFAULT_REGISTRY = /path/to/registry

# CWB command names
SimpleCQP::CQP_CMD = 'cqp'
SimpleCQP::CWB_LEXDECODE_CMD = 'cwb-lexdecode'

SimpleCQP::TEMP_DIR = '/tmp/'
