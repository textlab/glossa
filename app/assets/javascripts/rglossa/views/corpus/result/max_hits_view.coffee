App.CorpusResultMaxHitsView = Em.TextField.extend
  valueBinding: Em.Binding.oneWay('controller.maxHits')

  action: 'setMaxHits'
