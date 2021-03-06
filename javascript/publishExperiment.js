/* --------------------------------------------------------------------------------
 *
 *  specific functions for publishExperiment.jsp
 *
 * -------------------------------------------------------------------------------- */

function setupPage() {
	
    var itemDetails = createDialog(".itemDetails", {width: 700, height: 800, title: "<center>Experiment Details</center>"});
	
    var chooseUser = createDialog(".chooseUserDetails", {width: 500, height: 500, title: "<center>Grant Array Access to Individual</center>"});
	
    var confirmGrantAccessToPublic = createDialog(".confirmGrantAccessToPublic" , {width: 500, height: 300, title: "<center>Grant Open Access</center>"});
	
    var tableRows = getRows();
    stripeAndHoverTable( tableRows );
	
    tableRows.each(function(){
	$(this).find("td.details").click( function() {
        	var experimentID = $(this).parent("tr").attr("id"); 
		$.get(contextPath + "/web/experiments/showExpDetails.jsp", 
			{experimentID: experimentID},
                        function(data){
                                itemDetails.dialog("open").html(data);
                                closeDialog(itemDetails);
                        });
            });
          
	$(this).find("td.chooseUser").click( function() {
		var experimentID = $(this).parent("tr").attr("id"); 
		var experimentName =  $(this).parent("tr").find("td.experimentName").text(); 
                  $.get(contextPath + "/web/common/chooseUser.jsp", 
			{experimentID: experimentID, experimentName:experimentName},
                        function(data){
                                chooseUser.dialog("open").html(data);
                                closeDialog(chooseUser);
                        });
            });
						
            $(this).find("td.grantToPublic").click( function() {
                  var experimentID = $(this).parent("tr").attr("id"); 
                  var experimentName =  $(this).parent("tr").find("td.experimentName").text();   
                 
		$.get(contextPath + "/web/experiments/confirmGrantAccessToPublic.jsp", 
                        {experimentID: experimentID, experimentName:experimentName},
                        function(data){
                                confirmGrantAccessToPublic.dialog("open").html(data);
                                closeDialog(confirmGrantAccessToPublic);
                                $('input[name=grant]').attr('checked', false);
                        });
            });
    });
}
