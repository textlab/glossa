/*
* File: GlossaViewport.ui.js
* Date: Thu May 06 2010 16:56:47 GMT+0200 (CEST)
* 
* This file was generated by Ext Designer version xds-1.0.0.9.
* http://www.extjs.com/products/designer/
*
* This file will be auto-generated each and everytime you export.
*
* Do NOT hand edit this file.
*/

App.GlossaViewportUi = Ext.extend(Ext.Viewport, {
  layout: 'border',
  id: 'viewport',
  initComponent: function() {
    this.items = [
      {
      id: 'north-panel',
      xtype: 'panel',
      title: '<img align="right" alt="Tekstlab-hjemmeside" border="0" src="' + urlRoot + 'images/tllogo_110x24_bw_glowwhite.png">',
      region: 'north',
      width: 100,
      height: 65,
      bodyStyle: 'font-size: 32px; font-family: trebuchet MS; padding: 3px 5px 5px 5px; color: #444444; background-color: #efefef',
      collapsible: false,
      items: [{
        xtype: 'box',
        autoEl: {
          html: 'Glossa'
        }
      }]
    },
    {
      xtype: 'tabpanel',
      ref: 'centerTabpanel',
      activeTab: 0,
      region: 'center'
    },
    {
      xtype: 'panel',
      region: 'south',
      width: 100,
      ref: 'southPanel'
    }
    ];
    App.GlossaViewportUi.superclass.initComponent.call(this);
  }
});
