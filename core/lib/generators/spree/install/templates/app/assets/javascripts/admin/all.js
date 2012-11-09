// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
<% if options[:lib_name] == 'spree' %>
//= require admin/spree_core
//= require admin/spree_auth
//= require admin/spree_api
//= require admin/spree_promo
<% else %>
//= require admin/<%= options[:lib_name].gsub("/", "_") %>
<% end %>
//= require_tree .
