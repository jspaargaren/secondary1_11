import { withPluginApi } from 'discourse/lib/plugin-api';

var inject = Ember.inject;

export default {
	name: 'jerome-plugin',
	initialize(container) {
		if(Discourse.currentUser && Discourse.currentUser.custom_fields && Discourse.currentUser.custom_fields.encryptStatus == 'true'){
			Discourse.SiteSettings.encrypt_enabled = true;
		}else{
			Discourse.SiteSettings.encrypt_enabled = false;
		}
	},
};
