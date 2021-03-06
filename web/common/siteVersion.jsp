<%--
 *  Author: Cheryl Hornbaker
 *  Created: March, 2009
 *  Description:  The web page created by this file displays info on the versions the site is running.        
 *
 *  Todo: 
 *  Modification Log:
 *      
--%>

<%@ include file="/web/access/include/login_vars.jsp" %>

<jsp:useBean id="myDbUtils" class="edu.ucdenver.ccp.PhenoGen.util.DbUtils"> </jsp:useBean>
<%
        extrasList.add("index.css");

	String[] versionValues = myDbUtils.getDBVersion(dbConn);
	String dbVersion = versionValues[0];
	String dbUpdateDate = versionValues[1];
	//mySessionHandler.createSessionActivity(session.getId(), "Looked at site version page", dbConn);

%>
<%@ include file="/web/common/basicHeader.jsp" %>

<script type="text/javascript">
        var crumbs = ["Version Information"];
</script>

        <div id="overview-content">
        <div id="welcome" style="height:735px; width:980px;">

                <h2>PhenoGen Website Version</h2>
                <p>
		Version: &nbsp; <%=dbVersion%> <BR>
		Last updated: &nbsp; <%=dbUpdateDate%> 
		</p>
		<h2>Tools Used on This Website</h2>
		<p><a href="http://www.cisreg.ca/cgi-bin/oPOSSUM/opossum" target="POSSUM Master">Promoter (oPOSSUM)</a>:&nbsp;&nbsp; version 2.0</p>
		<p><a href="http://meme.nbcr.net/meme" target="MEME Master">Promoter (MEME)</a>:&nbsp;&nbsp; version 4.1</p>
		<p><a href="http://www.r-project.org/" target="R Master">R</a>:&nbsp;&nbsp;version 2.11.1</p>
		<p><a href="http://www.bioconductor.org/" target="R Master">BioConductor</a>:&nbsp;&nbsp;version 2.6</p>
		<!-- <p><a href="http://www.atlassian.com/" target="JIRA">JIRA</a>: &nbsp;&nbsp;version 3.1.1-#81 Professional Edition</p> -->
		<p><a href="<%=helpDir%>Annotation_Overview.htm">iDecoder</a>: &nbsp;&nbsp;Last updated on March 20, 2012 with annotation data from the following sources:</p>
		</p>
		<ul>
			<li>Annotation file for Affymetrix Genechip Drosophila Genome [DrosGenome1] na32
			<li>Annotation file for Affymetrix GeneChip Human Genome U133 Plus 2.0[HG-U133_Plus_2], na32
			<!-- <li>Annotation file for Affymetrix Genechip Human Genome U95Av2 [HG_U95Av2], na28 -->
			<li>Annotation file for Affymetrix Genechip Mouse Exon 1.0 ST Array, na32
			<li>Annotation file for Affymetrix GeneChip Mouse Expression Array MOE430A [MOE430A], na32
			<li>Annotation file for Affymetrix GeneChip Mouse Expression Array MOE430B [MOE430B], na32
			<li>Annotation file for Affymetrix GeneChip Mouse Genome 430A 2.0 [Mouse430A_2], na32
			<li>Annotation file for Affymetrix GeneChip Mouse Genome 430 2.0 [Mouse430_2], na32
			<li>Annotation file for Affymetrix Genechip Murine Genome U74A [MG_U74A], <B>na20</B>
			<li>Annotation file for Affymetrix Genechip Murine Genome U74Av2 [MG_U74Av2], <b>na22</b>
			<li>Annotation file for Affymetrix Genechip Murine Genome U74Bv2 [MG_U74Bv2], <b>na22</b>
			<li>Annotation file for Affymetrix Genechip Murine Genome U74Cv2 [MG_U74Cv2], <b>na22</b>
			<li>Annotation file for Affymetrix Genechip Rat Exon 1.0 ST Array, na32
			<li>Annotation file for Affymetrix GeneChip Rat Expression Array RAE230A [RAE230A], na32
			<li>Annotation file for Affymetrix Genechip Rat Genome U34A [RG_U34A], na32
			<!-- <li>Annotation file for Affymetrix Genechip Rat Genome U34C [RG_U34C], na23 -->
			<li>Annotation file for Amersham Codelink UniSet Mouse I 
			<li>Annotation file for Codelink Rat Whole Genome 
			<li>Annotation file for Codelink Mouse Whole Genome 
			<li>Location data from Ensembl for Mouse, Human, and Rat from Ensembl Genes 66 
			<li>FlyBase gene_map_table_fb_2011_09.tsv file and fbgn_NAseq_Uniprot_fb_2011_09.tsv 
			<li>MGI database links file generated from the ACC_Accession table on 3/20/2012
			<li>MGI_Coordinate.rpt links file, downloaded 3/20/2012 
			<li>NCBI gene2accession file, downloaded 3/20/2012
			<li>NCBI gene2unigene file, downloaded 3/20/2012
			<li>NCBI gene_info file, downloaded 3/20/2012
			<li>NCBI homologene.data file, build 64 
			<li>RGD GENES file, last updated on 3/20/2011
			<li>SwissProt uniprot_sprot.dat file, last updated on 3/20/2012
		</ul>


<%@ include file="/web/common/footer.jsp" %>
