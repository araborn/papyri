$(function() {

	$.ajaxSettings.traditional = true;

	$('a.papyri-facet').on('click', function(e) {
		e.preventDefault();
		$(this).toggleClass('papyri-facet-active');

		request = {};
		$('ul.papyri-facets').each(function(){
			facet = $(this).attr('data-papyri-facet');
			values = $.map($(this).children('li').children('.papyri-facet'), function(elem, i) {
				return $(elem).hasClass("papyri-facet-active") ? $(elem).attr('data-papyri-facet-value') : null;
			});
			request[facet] = values;
		});

		$('#papyri-results').load('query', $.param(request));
		
	});

  searchForm = $('form.papyri-complex-search')
  searchFields = $(searchForm).children('.search-fields');

  getField = function(name, index, callback) {
    $.ajax({
      url: papyri_app_root + '/search-field',
      data: {
        name: name,
        index: index
      },
      dataType: 'html',
      success: function(data) {
        callback(data);
      }

    });
  }

  $(searchFields).on('change', 'select.field', function(e) {

    parentFieldset = $(this).parent();

    getField(
      $(this).children('option:selected').attr('value'), 
      $(parentFieldset).index() + 1, 
      function(field) {
        $(parentFieldset).replaceWith($(field));
      }
    );
  });

  $(searchForm).find('#add').on('click', function(e) {
    e.preventDefault();
    fields = $(searchFields).children('fieldset');
    console.log(fields);
    lastField = $(fields).last();
    getField(
      'material',
      fields.length + 1,
      function(field) {
        $(field).insertAfter(lastField);
      }
    );
  });

  $(searchFields).on('click', '.add-or', function(e) {
    e.preventDefault();
    parentFieldset = $(this).parent();
    termField = $(parentFieldset).find('.term').first();

    orDiv = $('<div class="or"></div>').append($(termField).clone())
    $(parentFieldset).append(orDiv);
    
  });

  $(searchFields).on('click', '.remove', function(e) {
    e.preventDefault();
    parentFieldset = $(this).parent();
    parentFieldset.remove();
  });

});