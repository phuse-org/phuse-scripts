(function() {
/**
 * Shiny Registration
 */

var directoryInputBinding = new Shiny.InputBinding();
$.extend(directoryInputBinding, {
  find: function(scope) {
    return( $(scope).find(".directory-input") );
  },
  initialize: function(el) {
    // called when document is ready using initial values defined in ui.R
    // documented in input_binding.js but not in docs (articles)
  },
  getId: function(el) {
    return($(el).attr('id'));
  },
  getValue: function(el) {
    return($(el).data('val') || 0);
  },
  setValue: function(el, value) {
    $(el).data('val', value);
  },
  receiveMessage: function(el, data) {
    // This is used for receiving messages that tell the input object to do
    // things, such as setting values (including min, max, and others).
    // documented in input_binding.js but not in docs (articles)
    var $widget = $(el).parentsUntil('.directory-input-container').parent();
    var $path = $widget.find('input.directory-input-chosen-dir');

    console.log('message received: ' + data.chosen_dir);

    if (data.chosen_dir) {
      $path.val(data.chosen_dir);
      $path.trigger('change');
    }
  },
  subscribe: function(el, callback) {
    $(el).on("click.directoryInputBinding", function(e) {
      var $el = $(this);
      var val = $el.data('val') || 0;
      $el.data('val', val + 1);

      console.log('in subscribe: click');
      callback();
    });
  },
  unsubscribe: function(el) {
    $(el).off(".directoryInputBinding");
  }
});

Shiny.inputBindings
  .register(directoryInputBinding, "oddhypothesis.directoryInputBinding");


})();
