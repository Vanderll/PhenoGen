<%--
 *  Author: Cheryl Hornbaker
 *  Created: Nov, 2006
 *  Description:  This file formats the MEME files.
 *
 *  Todo: 
 *  Modification Log:
 *      
--%>

<%@ include file="/web/geneLists/include/geneListHeader.jsp"  %> 

<% 	formName = "promoter.jsp";
	request.setAttribute( "selectedTabId", "promoter" );

	optionsList.add("geneListDetails");
	optionsList.add("chooseNewGeneList");

	int itemID = (request.getParameter("itemID") != null ? Integer.parseInt((String) request.getParameter("itemID")) : -99);
	
	log.debug("in memeResults. itemID = " + itemID);

	GeneListAnalysis thisGeneListAnalysis = 
			myGeneListAnalysis.getGeneListAnalysis(itemID, dbConn);
	ParameterValue[] myParameterValues = thisGeneListAnalysis.getParameterValues();
	int upstreamLength = Integer.parseInt(thisGeneListAnalysis.getThisParameter("Sequence Length"));
			
	GeneList thisGeneList = thisGeneListAnalysis.getAnalysisGeneList();
        String memeDir = thisGeneList.getMemeDir(thisGeneList.getGeneListAnalysisDir(userLoggedIn.getUserMainDir()));
        String memeFileName = 
		thisGeneList.getMemeFileName(memeDir, thisGeneListAnalysis.getCreate_date_for_filename()) + 
		".html";

	log.debug("memeDir = "+memeDir);


	String[] memeResults = myFileHandler.getFileContents(new File(memeFileName), "withSpaces");
        mySessionHandler.createGeneListActivity("Viewed MEME Results for gene list", dbConn);
/*


        String action = (String)request.getParameter("action");

	if ((action != null) && action.equals("Download")) {
		request.setAttribute("fullFileName", memeFileName);
                myFileHandler.downloadFile(request, response);
		// This is required to avoid the getOutputStream() has already been called for this response error
		out.clear();
		out = pageContext.pushBody(); 

        	mySessionHandler.createSessionActivity(session.getId(), 
                	"Downloaded MEME Results for " + thisGeneList.getGene_list_name(),
			dbConn);
	} else {
	}

*/

%>
<%@ include file="/web/common/header.jsp" %>
	<script type="text/javascript">
		crumbs = ["Home", "Research Genes", "Promoter"];
	</script>

	<%@ include file="/web/geneLists/include/viewingPane.jsp" %>

	<%@ include file="/web/geneLists/include/geneListToolsTabs.jsp" %>

	<div class="dataContainer" >
	<div id="related_links">
		<div class="action" title="Return to select a different promoter analysis">
			<a class="linkedImg return" href="promoter.jsp">
			<%=fiveSpaces%>
			Select Another Promoter Analysis
			</a>
		</div>
	</div>
	<div class="brClear"></div>

	<div class="title"> Parameters Used:</div>
	<table class="list_base" cellpadding="0" cellspacing="3">
		<tr class="col_title">
			<th class="noSort">Parameter Name</th>
			<th class="noSort">Value</th>
		</tr>
		<% for (int i=0; i<myParameterValues.length; i++) {
			String value = (myParameterValues[i].getValue().equals("zoops") ? "Zero or one per sequence" : 
				(myParameterValues[i].getValue().equals("oops") ? "One per sequence" : 
					(myParameterValues[i].getValue().equals("tcm") ? "Any number of repetitions" : 
					myParameterValues[i].getValue())));
			 %>
			<tr>
			<td width=30%><b><%=myParameterValues[i].getParameter()%>:</b> </td>
			<td width=70%><%=value%></td>
			</tr>
		<% } %>
	</table>
	
	<a href="http://meme.nbcr.net/meme4_4_0/meme-intro.html" target="_blank">MEME Reference</a>
	
<%
	for (int i=0; i<memeResults.length; i++) {
		%> <%=memeResults[i]%> <%
	}
%>

<%@ include file="/web/common/footer.jsp" %>
