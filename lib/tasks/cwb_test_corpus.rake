namespace :cwb_test_corpus do
  desc "Create CWB test corpus."
  task :create do 't'
    Dir.chdir "test/cwb_test_data"

    sh "bash  ./create_test_corpus.sh"
  end

  desc "Delete CWB test corpus."
  task :delete do 't'
    Dir.chdir "test/cwb_test_data"

    sh "bash  ./delete_test_corpus.sh"
  end
end
