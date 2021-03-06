
<%@ include file="/web/common/session_vars.jsp" %>

<%
	extrasList.add("fancyBox/jquery.fancybox.js");
	extrasList.add("jquery.fancybox.css");
	extrasList.add("jquery.twosidedmultiselect.js");
	extrasList.add("tsmsselect.css");	

%>


<%@ include file="/web/common/header_noMenu.jsp" %>

	<style type="text/css">
		/* Recommended styles for two sided multi-select*/
		.tsmsselect {
			width: 40%;
			float: left;
		}
		
		.tsmsselect select {
			width: 100%;
		}
		
		.tsmsoptions {
			width: 20%;
			float: left;
		}
		
		.tsmsoptions p {
			margin: 2px;
			text-align: center;
			font-size: larger;
			cursor: pointer;
		}
		
		.tsmsoptions p:hover {
			color: White;
			background-color: Silver;
		}
	</style>
	<script>
		function displayWorking(){
			document.getElementById("wait1").style.display = 'block';
			document.getElementById("circosError1").style.display = 'none';
			return true;
		}
		function hideWorking(){
			document.getElementById("wait1").style.display = 'none';
			document.getElementById("circosError1").style.display = 'none';		
		}	
	</script>
<% 
			//
			// Initialize some variables
			//
			String iframeURL = null;
			String geneSymbol= null;
			String geneCentricPath = null;			
			String ensemblIdentifier = null;
			String transcriptClusterFileName = null;			
			String species = null;
			String longSpecies = null;
			String selectedTranscriptValue = null;
			String transcriptClusterID = null;
			String transcriptClusterChromosome= null;
			String transcriptClusterStart=null;
			String transcriptClusterStop=null;		
			String selectedCutoffValue = null;
			String[] selectedChromosomes = null;
			String chromosomeString = null;
			String[] transcriptClusterArray = null;
			int[] transcriptClusterArrayOrder = null;
			Boolean transcriptError = null;
			Boolean selectedChromosomeError = null;
			Boolean circosReturnStatus = null;
			String timeStampString = null;
			Boolean allowChromosomeSelection = false;






			
			//
			//Configure Inputs from session variables.
			//
			
			LinkedHashMap inputHash = new LinkedHashMap();

			geneSymbol =(String)session.getAttribute("geneSymbol");
			inputHash.put("geneSymbol",geneSymbol);

			geneCentricPath =(String)session.getAttribute("geneCentricPath");
			inputHash.put("geneCentricPath",geneCentricPath);
			Integer tmpIndex = geneCentricPath.substring(1,geneCentricPath.length()-1).lastIndexOf('/');			
			inputHash.put("length",tmpIndex);

			ensemblIdentifier = geneCentricPath.substring(tmpIndex+2,geneCentricPath.length()-1);
			inputHash.put("ensemblIdentifier",ensemblIdentifier);
			inputHash.put("transcriptClusterFileName",geneCentricPath+"tmp_psList_transcript.txt");
			transcriptClusterFileName = geneCentricPath.concat("tmp_psList_transcript.txt");
			
			if(ensemblIdentifier.substring(0,7).equals("ENSRNOG")){
				species="Rn";
				longSpecies = "Rattus norvegicus";
			}
			else if (ensemblIdentifier.substring(0,7).equals("ENSMUSG")){
				species="Mm";
				longSpecies="Mus musculus";
			}
			
			//
			// Read in transcriptClusterID information from file
			// Also get the chromosome that corresponds to the gene symbol
			//

          	transcriptClusterArray = myFileHandler.getFileContents(new File(transcriptClusterFileName));
          	String[] columns;
			log.debug("transcriptClusterArray length = "+transcriptClusterArray.length);
			// If the length of the transcript Cluster Array is 0, return an error.
			if(transcriptClusterArray.length == 0){
				log.debug(" the transcript cluster file is empty ");
				transcriptClusterArray = new String[1];
				transcriptClusterArray[0]="No Available	xx	xxxxxxxx	xxxxxxxx	Transcripts";
				log.debug(transcriptClusterArray[0]);
				transcriptError = true;
			}
			else{
				transcriptError = false;
            	// Need to change the transcript Cluster Array
				// Only include ambiguous if there are no other transcript clusters
				// Order the transcript cluster array so core is first, full is next, then extended, then ambiguous
				transcriptClusterArrayOrder = new int[transcriptClusterArray.length];
				for(int i=0; i < transcriptClusterArray.length; i++){
					transcriptClusterArrayOrder[i] = -1;
				}
				int numberOfTranscriptClusters = 0;
				for(int i=0; i < transcriptClusterArray.length; i++){
					columns = transcriptClusterArray[i].split("\t");
					if(columns[4].equals("core")){
						transcriptClusterArrayOrder[numberOfTranscriptClusters]=i;
						numberOfTranscriptClusters++;
					}
				}
				for(int i=0; i < transcriptClusterArray.length; i++){
					columns = transcriptClusterArray[i].split("\t");
					if(columns[4].equals("extended")){
						transcriptClusterArrayOrder[numberOfTranscriptClusters]=i;
						numberOfTranscriptClusters++;
					}
				}
				for(int i=0; i < transcriptClusterArray.length; i++){
					columns = transcriptClusterArray[i].split("\t");
					if(columns[4].equals("full")){
						transcriptClusterArrayOrder[numberOfTranscriptClusters]=i;
						numberOfTranscriptClusters++;
					}
				}
				if(numberOfTranscriptClusters < 1){
					for(int i=0; i < transcriptClusterArray.length; i++){
						columns = transcriptClusterArray[i].split("\t");
						if(columns[4].equals("ambiguous")){
							transcriptClusterArrayOrder[numberOfTranscriptClusters]=i;
							numberOfTranscriptClusters++;
						}
					}
					for(int i=0; i < transcriptClusterArray.length; i++){
						columns = transcriptClusterArray[i].split("\t");
						if(columns[4].equals("free")){
							transcriptClusterArrayOrder[numberOfTranscriptClusters]=i;
							numberOfTranscriptClusters++;
						}
					}
				}
			}
            // Populate the variable geneChromosome with the chromosome in the first line
			// The chromosome should always be the same for every line in this file
			String geneChromosome = "Y";			
            columns = transcriptClusterArray[0].split("\t");
            geneChromosome = columns[1];
            log.debug(" geneChromosome "+geneChromosome);
            String speciesGeneChromosome = species.toLowerCase() + geneChromosome;
            
			//
			// Create chromosomeNameArray and chromosomeSelectedArray 
			// These depend on the species
			//
			
			int numberOfChromosomes;
			String[] chromosomeNameArray = new String[25];

			String[] chromosomeDisplayArray = new String[25];
			String doubleQuote = "\"";
			String isSelectedText = " selected="+doubleQuote+"true"+doubleQuote;
			String isNotSelectedText = " ";
			String chromosomeSelected = isNotSelectedText;

			if(species.equals("Mm")){
				numberOfChromosomes = 20;
				for(int i=0;i<numberOfChromosomes-1;i++){
					chromosomeNameArray[i]="mm"+Integer.toString(i+1);
					chromosomeDisplayArray[i]="Chr "+Integer.toString(i+1);
				}
				chromosomeNameArray[numberOfChromosomes-1] = "mmX";
				chromosomeDisplayArray[numberOfChromosomes-1]="Chr X";
			}
			else{
				numberOfChromosomes = 21;
				// assume if not mouse that it's rat
				for(int i=0;i<numberOfChromosomes-1;i++){
					chromosomeNameArray[i]="rn"+Integer.toString(i+1);
					chromosomeDisplayArray[i]="Chr "+Integer.toString(i+1);
				}
				chromosomeNameArray[numberOfChromosomes-1] = "rnX";
				chromosomeDisplayArray[numberOfChromosomes-1]="Chr X";
			}
			
			
	boolean auto=false;
	//////////////////////////////////////////////////////////////////////////////////
	//
	// Evaluate entries on form	
	//
	//////////////////////////////////////////////////////////////////////////////////
	
	
	if (((action != null) && action.equals("Click to run Circos"))||auto) {

		// Get information about the transcript cluster

		if(request.getParameter("transcriptClusterID")!=null){
			selectedTranscriptValue = request.getParameter("transcriptClusterID");
			String[] transcriptArray = selectedTranscriptValue.split("\t");
			transcriptClusterID=transcriptArray[0];
			transcriptClusterChromosome = species.toLowerCase() + transcriptArray[1];
			transcriptClusterStart=transcriptArray[2];
			transcriptClusterStop=transcriptArray[3];
			log.debug(" Transcript Cluster ID: "+transcriptClusterID);
			log.debug(" Transcript Cluster Chromosome: "+transcriptClusterChromosome);
			log.debug(" Transcript Cluster Start: "+transcriptClusterStart);
			log.debug(" Transcript Cluster Stop: "+transcriptClusterStop);
		}
		// Get information about the cutoff value
		if(request.getParameter("cutoffValue")!=null){
			selectedCutoffValue = request.getParameter("cutoffValue");
			log.debug(" Selected Cutoff Value " + selectedCutoffValue);
			
		}
		
		// Get information about which chromosomes to view

		if(request.getParameter("chromosomes")!=null){			
			selectedChromosomes = request.getParameterValues("chromosomes");
			log.debug("Getting selected chromosomes");
			chromosomeString = "";
			selectedChromosomeError = true;
			for(int i=0; i< selectedChromosomes.length; i++){
				chromosomeString = chromosomeString + selectedChromosomes[i] + ";";
				if(selectedChromosomes[i].equals(speciesGeneChromosome)){
					selectedChromosomeError=false;
				}
			}
			log.debug(" Selected Chromosomes: " + chromosomeString);
			log.debug(" selectedChromosomeError: " + selectedChromosomeError);
			// We insist that the chromosome string include speciesGeneChromosome 
		}
		else if(request.getParameter("chromosomeSelectionAllowed")!=null){
			// We previously allowed chromosome selection, but now we got no chromosomes back
			// Therefore we did not include the desired chromosome
			selectedChromosomeError=true;
		}
		else{
			log.debug("could not get selected chromosomes");
			log.debug("and we did not previously allow chromosome selection");
			log.debug("therefore include all chromosomes");
			// we are not allowing chromosome selection.  Include all chromosomes.
			selectedChromosomes = new String[numberOfChromosomes];
			selectedChromosomeError=false;
			chromosomeString = "";
			for(int i=0; i< numberOfChromosomes; i++){
				chromosomeString = chromosomeString + chromosomeNameArray[i] + ";";
				selectedChromosomes[i]=chromosomeNameArray[i];
			}
			allowChromosomeSelection=true;  // next time allow chromosome selection
		}
		
		if(!selectedChromosomeError){
			//
			// Initialize variables for calling perl scripts (which will call Circos executable)
			//
//
//			Change below for dev, test, prod
//
	
			String perlScriptDirectory = (String)session.getAttribute("perlDir")+"scripts/";
			String perlEnvironmentVariables = (String)session.getAttribute("perlEnvVar");
			//
			// The next line needs to be changed depending on dev, test, production
			//
			//
                        perlEnvironmentVariables += ":/usr/bin/perl5.10:/usr/local/circos-0.62-1/lib:/usr/local/circos-0.62-1/bin";


			String filePrefixWithPath = (String)session.getAttribute("geneCentricPath")+transcriptClusterID+"_circos";
			// create the short svg directory name which incoporates the date for uniqueness
			java.util.Date dNow = new java.util.Date( );
   			SimpleDateFormat ft = new SimpleDateFormat ("yyyyMMddhhmmss");
			timeStampString = ft.format(dNow);
		//
		// Get the database connection properties
		//
		Properties myProperties = new Properties();
		File myPropertiesFile = new File(dbPropertiesFile);
		myProperties.load(new FileInputStream(myPropertiesFile));
		String dsn = "dbi:"+ myProperties.getProperty("PLATFORM")+ ":" + myProperties.getProperty("DATABASE");
		String OracleUserName = myProperties.getProperty("USER");
		String password = myProperties.getProperty("PASSWORD");
     		String[] perlScriptArguments = new String[18];
     		// the 0 element in the perlScriptArguments array must be "perl" ??
                perlScriptArguments[0] = "perl";
     		// the 1 element in the perlScriptArguments array must be the script name including path
                //
		// The following 2 lines may need to be changed depending on dev, test, production
		//
		//
                perlScriptArguments[1]=perlScriptDirectory+"callCircos.pl";
     		perlScriptArguments[2]=ensemblIdentifier;
     		perlScriptArguments[3]=geneSymbol;
     		perlScriptArguments[4]=transcriptClusterID;
     		perlScriptArguments[5]="transcript";
     		perlScriptArguments[6]=transcriptClusterChromosome;
     		perlScriptArguments[7]=transcriptClusterStart;
     		perlScriptArguments[8]=transcriptClusterStop;
     		perlScriptArguments[9]=selectedCutoffValue;
     		perlScriptArguments[10]=species;
     		perlScriptArguments[11]=chromosomeString;
     		perlScriptArguments[12]=geneCentricPath;
     		perlScriptArguments[13]=timeStampString;
     		perlScriptArguments[14]="All";
     		perlScriptArguments[15]=dsn;
     		perlScriptArguments[16]=OracleUserName;
     		perlScriptArguments[17]=password;
			log.debug(" Calling createCircosFiles from GeneDataTools");
			//
			// call perl script
			//
     		GeneDataTools gdtCircos=new GeneDataTools();
        	circosReturnStatus = gdtCircos.createCircosFiles(perlScriptDirectory,perlEnvironmentVariables,perlScriptArguments,filePrefixWithPath);
        	if(circosReturnStatus){
        		log.debug("Circos run completed successfully");
//
//
// The next line needs to be changed based on dev, test and production
//

       			String shortGeneCentricPath = geneCentricPath.substring(geneCentricPath.indexOf("/PhenoGenTEST/"));
				String svgFile = shortGeneCentricPath+transcriptClusterID+"_"+timeStampString+"/svg/circos_new.svg";
				iframeURL = svgFile;
				allowChromosomeSelection=true;  // After the first time they run circos, let them select the chromosomes.
			}
			else{
				log.debug("Circos run failed");
				// be sure iframeURL is still null
				iframeURL = null;
			}
			
		}
	}
	
	// This is the end of the first big scriptlet
%>

<div id="info">
		<div class="title">Genome-wide eQTL Information</div>
      	<table name="knownItems" class="list_base" cellpadding="0" cellspacing="3" >
      	<tr>
      		<td>
      			<strong>Species:</strong> 
      		</td> 
      		<td id="species" style="border: 1px solid black; border-radius:5px; font-weight: bold; text-align: center;">
      			<%=longSpecies%>
      		</td>
      	</tr>
      	<tr>
      		<td>
      			<strong>Gene Symbol: </strong>
      		</td>
      		<td id="geneSymbol" style="border: 1px solid black; border-radius:5px; font-weight: bold; text-align: center;">
      			<%=geneSymbol%>
      		</td>
		</tr>
      	<tr>
      		<td>
      			<strong>Ensembl Gene Name:</strong> 
      		</td>
      		<td style="border: 1px solid black; border-radius:5px; font-weight: bold; text-align: center;">
      			<%=ensemblIdentifier%>
      		</td>
      	</tr>
      	</table>
<BR>
</div>

<div id="circosError1" style="text-align:center;">

</div>

<script>
		document.getElementById("circosError1").style.display = 'none';
</script>



<%
if(transcriptError==null){
%>
	<script>
	document.getElementById("circosError1").innerHTML = "There was an error retrieving transcripts for <%=geneSymbol%>.  The website administrator has been informed.";
	document.getElementById("circosError1").style.display = 'block';
	document.getElementById("circosError1").style.color = "#ff0000";
	</script>
<%
}
else if(transcriptError)
{
%>
	<script>
	document.getElementById("circosError1").innerHTML = "There are no available transcript cluster IDs for <%=geneSymbol%>.  Please choose a different gene to view eQTL.";
	document.getElementById("circosError1").style.display = 'block';
	document.getElementById("circosError1").style.color = "#ff0000";
	</script>
<%
} 
else 
{

	// go ahead and make the rest of the form for entering options
%>

	<div class="title">Select Options Below:
	
	</div>

	
	
	<form	
		name="LocusSpecificEQTLForm" 
		method="post" 
		action="<%=formName%>" 
		enctype="application/x-www-form-urlencoded"> 

      	<table name="items" class="list_base" cellpadding="0" cellspacing="3" >
 
		<tr>
			<td>
				<strong>P-value Threshold for Highlighting:</strong> 
					<div class="inpageHelp" style="display:inline-block;">
					<img id="Help9a" src="../images/icons/help.png"/>
					</div>
			</td>
			<td>
				<%
				selectName = "cutoffValue";
				if(selectedCutoffValue!=null){
					selectedOption = selectedCutoffValue;
				}
				else{
					selectedOption = "2.0";					
				}
				onChange = "";
				style = "";
				optionHash = new LinkedHashMap();
                        	optionHash.put("1.0", "0.10");
                        	optionHash.put("2.0", "0.01");
                        	optionHash.put("3.0", "0.001");
                        	optionHash.put("4.0", "0.0001");
                        	optionHash.put("5.0", "0.00001");
				%>
				<%@ include file="/web/common/selectBox.jsp" %>
			</td>			
		</tr>
		
		<tr>
			<td>
							<strong>Transcript Cluster ID:</strong>
							<div class="inpageHelp" style="display:inline-block;">
							<img id="Help9b" src="../images/icons/help.png"/>
							</div>
			</td>
			<td>
			<%
				// Set up the select box:
				selectName = "transcriptClusterID";
				if(selectedTranscriptValue!=null){
					log.debug(" selected Transcript Value "+selectedTranscriptValue);
					selectedOption = selectedTranscriptValue;
				}
				onChange = "";
				style = "";
				optionHash = new LinkedHashMap();	
				String transcriptClusterString = null;
				for (int i=0; i<transcriptClusterArray.length; i++) {
				
					if(transcriptClusterArrayOrder[i] >-1){
				
				
                		columns = transcriptClusterArray[transcriptClusterArrayOrder[i]].split("\t");
                		transcriptClusterString = transcriptClusterArray[transcriptClusterArrayOrder[i]];
                		optionHash.put(transcriptClusterString,columns[0]+ " " + columns[4]);
                	}
				}
				//log.debug(" optionHash for Transcript Cluster ID: "+optionHash);

			%>
			<%@ include file="/web/common/selectBox.jsp" %>
			</td>
		</tr>
		
		
		<%if(allowChromosomeSelection||(request.getParameter("chromosomeSelectionAllowed")!=null)){%>
		<input type="hidden" id="chromosomeSelectionAllowed" name="chromosomeSelectionAllowed" value="Y" />
		<div id=chromosomeMultiselect>
		<tr>
			<td>
					<BR>
			</td>
		</tr>
		<tr>
			<td>
				<strong>Chromosomes:</strong>
				<div class="inpageHelp" style="display:inline-block;">
				<img id="Help9c" src="../images/icons/help.png"/>
				</div>
			</td>
			<td>
				<%=tenSpaces%><strong>Excluded</strong><%=twentyFiveSpaces%><%=twentySpaces%><strong>Included</strong>
			</td>
		</tr>
		<tr>
			<td>

			</td>

			<td rowspan="6">
				
				<select name="chromosomes" class="multiselect" size="8" multiple="true">
				
					<% 
					
					for(int i = 0; i < numberOfChromosomes; i ++){
						chromosomeSelected=isNotSelectedText;
						if(chromosomeDisplayArray[i].substring(4).equals(geneChromosome)){
							chromosomeSelected=isSelectedText;
						}
						else {
							if(selectedChromosomes != null){
								for(int j=0; j< selectedChromosomes.length ;j++){
									//log.debug(" selectedChromosomes element "+selectedChromosomes[j]+" "+chromosomeNameArray[i]);
									if(selectedChromosomes[j].equals(chromosomeNameArray[i])){
										chromosomeSelected=isSelectedText;
									}
								}
							}
						}


					%>
					
						<option value="<%=chromosomeNameArray[i]%>"<%=chromosomeSelected%>><%=chromosomeDisplayArray[i]%></option>
					
					<%} // end of for loop
					%>

				</select>

			</td>
		</tr>	

		<tr>
			<td>
					<BR>
			</td>
		</tr>
		<tr>
			<td>
					<BR>
			</td>
		</tr>
		<tr>
			<td style="text-align:center">
					The chromosome where the gene <BR>
					is physically located (Chr <%=geneChromosome%>)<BR>
					must be included.
			</td>
		</tr>
		<tr>
			<td style="text-align:center">
					<BR>
			</td>
		</tr>
		<tr>
			<td style="text-align:center">
					<BR>
			</td>
		</tr>		

		<%}
		else{%>
		<tr>
			<td>
			<BR>
			</td>
			<BR>
			<td>
			</td>
		</tr>
		</div>
		<%}%>
		
		
		
		
		
		<tr>	
				<td>
				<INPUT TYPE="submit" NAME="action" id="clickToRunCircos" Value="Click to run Circos" onClick="return displayWorking()">
				</td>
				<td>
					<a href="http://genome.cshlp.org/content/early/2009/06/15/gr.092759.109.abstract" target="_blank" style="text-decoration: none">Circos: An information aesthetic for comparative genomics.</a>
				</td>
		</tr>
      	</table>
	</form>

<BR>

	
	<div id="wait1" align="center"><img src="<%=imagesDir%>wait.gif" alt="Working..." text-align="center" >
	<BR />Preparing to run Circos...</div>


	<script>
			document.getElementById("wait1").style.display = 'none';
	</script>


  
            
     <script type="text/javascript">
     	  //var geneChromosome = "<%=speciesGeneChromosome%>";
     	  //console.log(geneChromosome);
          $(".multiselect").twosidedmultiselect();
          var selectedChromosomes = $("#chromosomes")[0].options;
     </script>

<%
} // end of if(transcriptError)
%>

<%
if((circosReturnStatus!=null)&&(!circosReturnStatus)){
%>
	<script>
	document.getElementById("circosError1").innerHTML = "There was an error running Circos.  The website administrator has been informed.";
	document.getElementById("circosError1").style.display = 'block';
	document.getElementById("circosError1").style.color = "#ff0000";
	</script>

<%
   } // end of checking circosReturnStatus 
%>



<%
if((selectedChromosomeError!=null)&&(selectedChromosomeError)){
	allowChromosomeSelection = true;
%>
	<script>
	document.getElementById("circosError1").innerHTML = "Chromosome " + <%=geneChromosome%> + " must be selected.";
	document.getElementById("circosError1").style.display = 'block';
	document.getElementById("circosError1").style.color = "#ff0000";
	</script>
<%
} // end of checking selectedChromosomeError 
%>

	
<%
	if(iframeURL!=null){
%>

	<script>
		document.getElementById("wait1").style.display = 'none';
	</script>

          <div id="mousewheeltext" align="center">
          <p>Inside border of Circos plot the mouse wheel zooms. </p>
          </div>
          <div id="iframe_parent" align="center">
               <iframe src=<%=iframeURL%> height=950 width=950  position=absolute scrolling="no" style="border-style:solid; border-color:rgb(139,137,137); border-radius:15px; -moz-border-radius: 15px; border-width:1px">
               </iframe>
          </div>



	
	
<%
}// end of if iframeURL != null
%>	
	
<div id="makingNewLines">

<% 
for(int i = 0; i < 25; i++){
%>
	<BR>
<%
}
%>

</div>


<div id="Help9aContent" class="inpageHelpContent" title="<center>Help</center>">
<div class="help-content">
<H3><center>P-value Threshold Options</center></H3>
<BR>
<BR>
Loci with p-values below the chosen threshold will be highlighted on the Circos plot in yellow; a line will connect the significant loci with the physical location of the gene.  
All p-values will be displayed on the Circos graphic as the negative log base 10 of the p-value.
</div>
</div>


<div id="Help9bContent" class="inpageHelpContent" title="<center>Help</center>"><div class="help-content">
<H3><center>Location Specific EQTL Options</center></H3>
<BR>
<BR>
On the Affymetrix Exon Array, gene level expression summaries are labeled as transcript clusters.  
Each gene may have more than one transcript cluster associated with it due to differences in annotation among databases and therefore, differences in which individual exons (probe sets) are included in the transcript cluster.  
Transcript clusters given the designation of &ldquo;core&rdquo; are based on well-curated annotation on the gene.  
&ldquo;Extended&rdquo; and &ldquo;full&rdquo; transcript clusters have are based on gene properties that are less thoroughly curated and more putative, respectively.  
Transcript clusters labeled as &ldquo;free&rdquo; or &ldquo;ambiguous&rdquo; have are highly putative for several reasons and therefore, are only included in the drop-down menu if no other transcript clusters are available.
</div>
</div>


<div id="Help9cContent" class="inpageHelpContent" title="<center>Help</center>"><div class="help-content">
<H3><center>Location Specific EQTL Options</center></H3>
<BR>
<BR>
Select chromosomes to be displayed in Circos plot by using arrows to move chromosomes to the box on the right.  
Moving chromosomes to the box on the left will eliminate them from the Circos plot.  
The chromosome where the gene is physically located MUST be included in the Circos plot.
</div>
</div>


<script>
	
	
	$(document).ready(function() {	
	

		//document.getElementById("circosError1").style.display = 'none';

	
		$('.fancybox').fancybox({
			width:$(document).width(),
			height:$(document).height()
  		});
  
  		$('.hiddenLink').fancybox({
			width:$(document).width(),
			height:$(document).height()
		});
		
		$('.inpageHelpContent').hide();
  
  		$('.inpageHelpContent').dialog({ 
  			autoOpen: false,
			dialogClass: "helpDialog", 
			height:300,
			zIndex: 3999
		});
		
 
  		$('#Help9a').click( function(){
  			$('#Help9aContent').dialog("open").css({'height':220,'font-size':12});
			$('.helpDialog').css({'top':450,'left':$(window).width()*0.08,'width':$(window).width()*0.33});
			return false;
  		});
  		$('#Help9b').click( function(){
  			$('#Help9bContent').dialog("open").css({'height':220,'font-size':12});
			$('.helpDialog').css({'top':450,'left':$(window).width()*0.08,'width':$(window).width()*0.33});
			return false;
  		}); 
  		$('#Help9c').click( function(){
  			$('#Help9cContent').dialog("open").css({'height':220,'font-size':12});
			$('.helpDialog').css({'top':450,'left':$(window).width()*0.08,'width':$(window).width()*0.33});
			return false;
  		}); 
	});

</script>

<%@ include file="/web/common/basicFooter.jsp" %>

