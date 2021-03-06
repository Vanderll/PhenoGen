<%--
 *  Author: Cheryl Hornbaker
 *  Created: August, 2010
 *  Description:  The web page created by this file displays the pathway results for a gene list
 *
 *  Todo: 
 *  Modification Log:
 *      
--%>

<%@ include file="/web/geneLists/include/geneListHeader.jsp"  %> 

<%
	log.info("in pathwayTab.jsp. user = " + user);

	request.setAttribute( "selectedTabId", "pathway" );
        extrasList.add("pathway.js");
	optionsList.add("geneListDetails");
	optionsList.add("chooseNewGeneList");
	optionsListModal.add("createNewPathway");

	int itemID = (request.getParameter("itemID") != null ? Integer.parseInt((String) request.getParameter("itemID")) : -99);
	if (itemID != -99) {
		response.sendRedirect("pathwayResults.jsp?itemID="+itemID);
	}

	GeneListAnalysis [] myAnalysisResults = null;
        String header = "";
        String columnHeader = "";
        String msg = "";
	String all="N";
	String button="";
	String title="";
	String type="";
	String createNew="";

        mySessionHandler.createGeneListActivity("On pathway tab ", dbConn);
%>
<%@ include file="/web/common/header.jsp" %>

	<script type="text/javascript">
		var crumbs = ["Home", "Research Genes", "Pathway"];
	</script>

	<%@ include file="/web/geneLists/include/viewingPane.jsp" %>
	<div class="page-intro">
		<p> Click on a pathway analysis name to view the results, or run a new analysis.
		</p>
	</div> <!-- // end page-intro -->

	<%@ include file="/web/geneLists/include/geneListToolsTabs.jsp" %>

	<div class="dataContainer" >
<%
		myAnalysisResults = 
        		myGeneListAnalysis.getGeneListAnalysisResults(userID, selectedGeneList.getGene_list_id(), "Pathway", dbConn);
		type = "Pathway";
%>
		<%@ include file="/web/geneLists/include/formatAnalysisResults.jsp" %>
	</div>

	<div class="deleteItem"></div>
	<div class="createPathway"></div>
	<script type="text/javascript">
		$(document).ready(function() {
			setupPage();
			setTimeout("setupMain()", 100); 
		});
	</script>

<%@ include file="/web/common/footer.jsp" %>
