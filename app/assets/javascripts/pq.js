
$(document).ready(function () {
	$('.datetimepicker').datetimepicker();
	$(".multi-select-action-officers").select2({width:'250px'});

	$('#allocation_response_response_action_accept').click(function (){
		$('#reason-textarea').addClass('hide');
	});
	$('#allocation_response_response_action_reject').click(function (){
		$('#reason-textarea').removeClass('hide');
	});
	$(".form-commission")
	.on("ajax:success", function(e, data, status, xhr){
		var pqid = $(this).data('pqid');
		$('#commission'+pqid).click();
		//get the div to refresh
		var divToFill = "question_allocation_" + $(this).data('pqid');
		//put the dat returned into the div
		$('#'+divToFill).html(data);
		//clear select list
		$('#action_officers_pq_action_officer_id-'+pqid).select2('data', null);
	}).on("ajax:error", function(e, xhr, status, error) {
		alert('fail');
		//TODO how should ux handle error? Add it to the list, alert, flash, etc...

	});
    $('.form-add-trim-link')
        .on('ajax:success', function(e, data, status, xhr) {
            console.log('ajax:success');
            //get the pq_id
            var pqid = $(this).data('pqid');
            console.log('pqid',pqid);
            //get the div to replace
            var $divToFill = $('trim_area_' + pqid);
            //put the data returned into the div
            $(divToFill).innerHTML(data);
        })
        .on('ajax:error', function(e, xhr, status, error) {
            alert('fail');
            //TODO how should ux handle error? Add it to the list, alert, flash, etc...

        });


    $('#search_member').bind('ajax:before', function() {
        $(this).data('params', { name: $("#minister_name").val() });
    });

    $('#search_member').bind('ajax:success', function(e, data, status, xhr){
        $( "#members_result" ).replaceWith(data);
        $("#members_result_select").select2({width:'250px'});
        $('#members_result_select_link').bind('ajax:before', function() {
            m_id = $("#members_result_select").val();
            m_name = $("#members_result_select option:selected").data('name');
            $("#minister_member_id").val(m_id);
            $("#minister_name").val(m_name);
            return false;
        });
    });

    $('.answer-pq-link').on('ajax:success', function(e, data, status, xhr){
        var pq_id = $(this).data('id');
        var divToFill = "#answer-pq-" + pq_id;
        $( divToFill ).html(data);
    });

    $('.trim-links-header').on('click', function () {
        $(this).children('.trim-links-form').show();
    });
    $('.trim-links-cancel').on('click', function (e) {
        e.stopPropagation();
        var $par = $(this).parent('.trim-links-form').first().hide();
    });
    $('.file-chooser').change(function () {
        var fileName = $(this).val();
        if (fileName.length > 0) {
            $(this).siblings('input:submit').show();
            $(this).prev('.file-choose-replace').text('Selected');
        } else {
            $(this).siblings('input:submit').hide();
            $(this).prev('.file-choose-replace').text('Choose file');
        }
    });
    $('.file-choose-replace').bind("click" , function () {
        $(this).next('.file-chooser').click();
    });

});  
