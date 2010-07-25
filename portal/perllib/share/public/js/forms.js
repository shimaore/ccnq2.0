$(document).ready(function() {
        $("form.validate").validate();

        $("div.provisioning:lt(50)").accordion();
        $("div.progressbar").progressbar();
});
