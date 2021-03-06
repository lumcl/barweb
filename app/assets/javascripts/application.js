// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets.sprockets-directives) for details
// about supported directives.
//
// require jquery
// require jquery_ujs
// require turbolinks
// require_tree .


$(document).ready(function () {

    $('.btn-form-submit').each(function () {
        $(this).data('save-text', '保存中...');
        $(this).click(function () {
            $(this).button('save');
            $(this).attr("disabled", true);
            this.form.submit();
        })
    });

    $('.datetimepicker').each(function () {
        $(this).datetimepicker({
            pickTime: false,
            useStrict: true
        }).bind('keydown', false);
    });


    $(".clickAll").click(function () {
        if ($(".clickAll").prop("checked")) {
            $("input[name='ids[]']").each(function () {
                $(this).prop("checked", true);
            });
        }
        else {
            $("input[name='ids[]']").each(function () {
                $(this).prop("checked", false);
            });
        }
    });
})
