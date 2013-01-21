App.MetadataAccordionController = Em.ArrayController.extend
  needs: 'corpus'
  contentBinding: 'controllers.corpus.metadataCategories'
