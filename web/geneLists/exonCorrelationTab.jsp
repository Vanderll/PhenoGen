<%--
 *  Author: Spencer Mahaffey
 *  Created: December, 2011
 *  Description:  The web page created by this file allows the user to
 *              select data to compute exon to exon correlations to look by eye for alternate splicing.
 *  Todo:
 *  Modification Log:
 *
--%>

<%@ include file="/web/geneLists/include/geneListHeader.jsp"  %>

<jsp:useBean id="myDataset" class="edu.ucdenver.ccp.PhenoGen.data.Dataset"> </jsp:useBean>

<%
        log.info("in exonCorrelationTab.jsp. user =  "+ user);

        extrasList.add("exonCorrelationTab.js");
		//extrasList.add("progressBar.js");
		optionsList.add("geneListDetails");
		optionsList.add("chooseNewGeneList");
        //if (selectedDataset.getDataset_id() != -99 && selectedDatasetVersion.getVersion() != -99) {
		//optionsList.add("download");
	//}

	request.setAttribute( "selectedTabId", "exonCorrelationTab" );

        mySessionHandler.createGeneListActivity("Looked at exon Correlation Values for a gene", dbConn);
%>

<%@ include file="/web/common/header.jsp" %>


	<script type="text/javascript">
		var crumbs = ["Home", "Research Genes", "Exon Correlation Values"];
	</script>
    <script language="JAVASCRIPT" type="text/javascript"><%
                String program = "exonCor";
                int duration = 120;
                        %>durationArray[0] = new durationRow('<%=program%>', <%=duration%>);
       </script>
	<%@ include file="/web/geneLists/include/viewingPane.jsp" %>

	<div class="page-intro">
		<% if (session.getAttribute("exonCorGeneFile")==null) { %> 
                        <p> Select a transcript you wish to view, zoom in/out, filter probesets by annotation, or compare two transcripts side by side. </p>
		<% } %>
	</div> <!-- // end page-intro -->

	<%@ include file="/web/geneLists/include/geneListToolsTabs.jsp" %>
    <div class="leftTitle">Exon-Exon Correlations</div>
    <div style="font-size:14px">
    <div id="wait1"><img src="<%=imagesDir%>wait.gif" alt="Working..." /><BR />Working...It may take up to 3 minutes the first time you run an exon correlation.</div>
    <%@ include file="/web/exons/exonCorrelationForm.jsp" %>
	
  	<%@ include file="/web/exons/exonCorrelationMain.jsp" %>
    </div><!-- end primary content-->

	<script>
		document.getElementById("wait1").style.display = 'none';
	</script>

<%@ include file="/web/common/footer.jsp" %>


