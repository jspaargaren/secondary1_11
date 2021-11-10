import Component from "@ember/component";
import { ajax } from 'discourse/lib/ajax';
import { withPluginApi } from 'discourse/lib/plugin-api';

export default Ember.Component.extend({
  
    getSecondaryGroups: function() {
       ajax("/secondary_group_api/viewgroup/"+this.get('username'), {
      type: 'GET',
      
    }) .then(users => {
      this.set("getSecondaryGroups", users);
    });
  }.property(),

});